import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../services/dataset/dataset_batch_cancellation_token.dart';
import '../../services/dataset/dataset_file_scanner.dart';
import '../../services/dataset/mirrored_output_file_system.dart';
import '../../services/platform/media_store_service.dart';
import '../entities/audio_file_ref.dart';
import '../entities/background_profile.dart';
import '../entities/dataset_audio_file.dart';
import '../entities/dataset_batch_config.dart';
import '../entities/dataset_batch_progress.dart';
import '../entities/dataset_file_failure.dart';
import '../entities/enums.dart';
import '../entities/processing_job.dart';
import '../ports/file_system_port.dart';
import '../ports/media_store_port.dart';
import '../repositories/profile_repository.dart';
import 'apply_profile_usecase.dart';

/// Builds an [ApplyProfileUseCase] whose output is mirrored under a separate
/// root for the dataset rooted at [sourceRoot]. The build is async because
/// resolving the public output folder touches platform storage APIs.
typedef DatasetApplyBuilder = Future<ApplyProfileUseCase> Function(
    String sourceRoot);

/// Orchestrates Dataset Batch Processing (a new, additive feature).
///
/// Recursively discovers files matching a suffix under a root folder and runs
/// each through [ApplyProfileUseCase] — the existing single-file engine — so no
/// audio/profile logic is duplicated. Output mirrors the source tree under a
/// separate public root (the per-run [ApplyProfileUseCase], built by
/// [_buildApply], is wired with a mirroring file system).
///
/// Designed for large datasets: files stream from the scanner, are processed
/// sequentially, and progress is emitted continuously. A failure on one file is
/// recorded and never aborts the rest. Cancellation is checked between files so
/// the in-flight file always finishes cleanly.
class ProcessDatasetUseCase {
  ProcessDatasetUseCase({
    required DatasetApplyBuilder buildApply,
    required ProfileRepository profiles,
    required DatasetFileScanner scanner,
    required FileSystemPort fileSystem,
    required MediaStorePort mediaStore,
  })  : _buildApply = buildApply,
        _profiles = profiles,
        _scanner = scanner,
        _fileSystem = fileSystem,
        _mediaStore = mediaStore;

  final DatasetApplyBuilder _buildApply;
  final ProfileRepository _profiles;
  final DatasetFileScanner _scanner;
  final FileSystemPort _fileSystem;
  final MediaStorePort _mediaStore;

  /// Runs the dataset job described by [config].
  ///
  /// Pass [cancelToken] to support cooperative cancellation. Pass [onlyPaths]
  /// to skip scanning and process exactly those source paths (used by the
  /// "Retry failed files" flow).
  Stream<DatasetBatchProgress> call(
    DatasetBatchConfig config, {
    DatasetBatchCancellationToken? cancelToken,
    List<String>? onlyPaths,
    Set<String> extensions = DatasetFileScanner.defaultExtensions,
    Duration perFileTimeout = const Duration(minutes: 15),
  }) async* {
    AppLogger.i('START_DATASET_PROCESSING');
    AppLogger.i('  root=${config.rootFolder}');
    AppLogger.i('  extensions=$extensions  perFileTimeout=$perFileTimeout');
    AppLogger.i('  onlyPaths=${onlyPaths?.length ?? 'null (full scan)'}');
    for (final sp in config.suffixProfiles) {
      AppLogger.i('  mapping: "${sp.suffix}" -> profile ${sp.profileId}'
          '${sp.coverImagePath == null ? '' : ' (+cover)'}');
    }

    // --- Resolve a profile per suffix up front. ---
    // Each suffix may map to a different profile (and thus different background
    // music). Distinct profile ids are fetched once and cached. A suffix whose
    // profile cannot be resolved is left out of [profileBySuffix]; files
    // matching it are later recorded as per-file failures.
    final profileBySuffix = <String, BackgroundProfile>{};
    final resolved = <String, BackgroundProfile?>{};
    String? firstError;
    for (final sp in config.suffixProfiles) {
      if (!resolved.containsKey(sp.profileId)) {
        final result = await _profiles.getById(sp.profileId);
        resolved[sp.profileId] = result.valueOrNull;
        firstError ??= result.failureOrNull?.message;
        AppLogger.i('RESOLVE_PROFILE ${sp.profileId}: '
            '${result.valueOrNull == null ? 'FAILED (${result.failureOrNull?.message})' : 'ok'}');
      }
      final profile = resolved[sp.profileId];
      // Each suffix carries its own thumbnail, chosen at selection time, so
      // override the resolved profile's cover art per suffix (two suffixes may
      // share a profile but want different — or no — thumbnails).
      if (profile != null) {
        profileBySuffix[sp.suffix] =
            profile.copyWith(coverImagePath: sp.coverImagePath);
      }
    }

    if (profileBySuffix.isEmpty) {
      AppLogger.w('START aborted: no backdrop resolved for any suffix.');
      yield DatasetBatchProgress(
        completed: true,
        failures: [
          DatasetFileFailure(
            filePath: config.rootFolder,
            error: firstError ?? 'No backdrop could be resolved for any suffix.',
          ),
        ],
      );
      return;
    }

    // --- Discover matching files. ---
    yield const DatasetBatchProgress(scanning: true);

    final List<String> paths;
    DatasetScanResult? scan;
    if (onlyPaths != null) {
      AppLogger.i('SCAN_SKIPPED: retrying ${onlyPaths.length} supplied path(s).');
      paths = onlyPaths;
    } else {
      // Drain the progressive scan, surfacing live counts as we go so the UI
      // never sits silent during a long recursive walk.
      await for (final tick in _scanner.scanProgressive(
        rootFolder: config.rootFolder,
        suffixes: config.suffixes,
        extensions: extensions,
      )) {
        if (cancelToken?.isCancelled ?? false) {
          AppLogger.i('CANCELLED during scan.');
          yield const DatasetBatchProgress(completed: true, cancelled: true);
          return;
        }
        if (tick.isDone) {
          scan = tick.result;
        } else {
          yield DatasetBatchProgress(
            scanning: true,
            scanDiscovered: tick.discovered,
            scanMatched: tick.matched,
            currentFolder: tick.currentDirectory,
          );
        }
      }
      paths = scan?.matchedPaths ?? const [];
    }

    final queue = paths.map(_describe).toList();
    final total = queue.length;
    AppLogger.i('SCAN result: matched=$total '
        '(audioFound=${scan?.audioFilesFound ?? '-'}, '
        'rootReadable=${scan?.rootReadable ?? '-'})');

    if (total == 0) {
      AppLogger.w('No files to process — completing with a no-match reason.');
      yield DatasetBatchProgress(
        completed: true,
        noMatchReason:
            scan == null ? null : _explainNoMatch(scan, config, extensions),
      );
      return;
    }

    yield DatasetBatchProgress(totalFiles: total);

    // Build the engine for this run; its file system mirrors the source tree
    // under the public output root (e.g. Music/EchoBug/<rootName>/...).
    AppLogger.i('BUILD_APPLY_START');
    final apply = await _buildApply(config.rootFolder);
    AppLogger.i('BUILD_APPLY_COMPLETE');

    // --- Process sequentially. ---
    var processed = 0;
    var successful = 0;
    var failed = 0;
    var skipped = 0;
    final failures = <DatasetFileFailure>[];

    for (final file in queue) {
      if (cancelToken?.isCancelled ?? false) {
        AppLogger.i('CANCELLED before file ${processed + 1}/$total.');
        break;
      }

      final fileName = p.basename(file.sourcePath);
      AppLogger.i('PROCESSING_FILE ${processed + 1}/$total: ${file.sourcePath}');

      yield DatasetBatchProgress(
        totalFiles: total,
        processedFiles: processed,
        successfulFiles: successful,
        failedFiles: failed,
        skippedFiles: skipped,
        currentFile: fileName,
        currentFolder: file.folderName,
        currentFileProgress: 0,
        currentStage: JobStage.preparing.name,
        failures: List.unmodifiable(failures),
      );

      // Skip files that vanished between discovery and processing.
      if (!await _fileSystem.exists(file.sourcePath)) {
        AppLogger.w('SKIP (vanished before processing): ${file.sourcePath}');
        skipped++;
        processed++;
        continue;
      }

      // Route the file to the profile of its matched suffix (longest wins).
      final suffix = DatasetFileScanner.matchedSuffix(
        file.sourcePath,
        config.suffixes,
        extensions,
      );
      final profile = suffix == null ? null : profileBySuffix[suffix];
      if (profile == null) {
        AppLogger.w('FAIL (no profile for suffix "$suffix"): ${file.sourcePath}');
        failed++;
        processed++;
        failures.add(DatasetFileFailure(
          filePath: file.sourcePath,
          fileName: fileName,
          error: suffix == null
              ? 'No configured suffix matched this file.'
              : 'No backdrop available for suffix "$suffix".',
        ));
        continue;
      }

      final source = AudioFileRef(
        path: file.sourcePath,
        name: fileName,
        ext: p.extension(file.sourcePath).replaceFirst('.', '').toLowerCase(),
      );

      try {
        AppLogger.i('APPLY_PROFILE_START suffix="$suffix" '
            'profile=${profile.name} file=$fileName');
        ProcessingJob? lastJob;
        // A single hung file (e.g. FFmpeg that never exits) must never block the
        // whole dataset: time out if no progress event arrives within the
        // window, then record a failure and move on.
        final jobs = apply.call(source, profile).timeout(
          perFileTimeout,
          onTimeout: (sink) {
            AppLogger.e('APPLY_TIMEOUT after $perFileTimeout: $fileName');
            sink.addError(
              TimeoutException('Processing timed out', perFileTimeout),
            );
            sink.close();
          },
        );
        await for (final job in jobs) {
          lastJob = job;
          yield DatasetBatchProgress(
            totalFiles: total,
            processedFiles: processed,
            successfulFiles: successful,
            failedFiles: failed,
            skippedFiles: skipped,
            currentFile: fileName,
            currentFolder: file.folderName,
            currentFileProgress: job.progress,
            currentStage: job.stage.name,
            failures: List.unmodifiable(failures),
          );
        }
        AppLogger.i('APPLY_PROFILE_COMPLETE file=$fileName '
            'stage=${lastJob?.stage.name}');

        if (lastJob?.stage == JobStage.completed) {
          // Engine wrote to an app-private staging path; publish it into the
          // public Music/EchoBug/<mirror> folder, then drop the staging copy.
          await _publish(config.rootFolder, source, lastJob?.outputPath);
          successful++;
        } else {
          failed++;
          failures.add(DatasetFileFailure(
            filePath: file.sourcePath,
            fileName: fileName,
            error: lastJob?.errorMessage ?? 'Processing failed.',
          ));
        }
      } catch (error, stackTrace) {
        AppLogger.e('APPLY_PROFILE_ERROR file=$fileName: $error');
        failed++;
        final timedOut = error is TimeoutException;
        failures.add(DatasetFileFailure(
          filePath: file.sourcePath,
          fileName: fileName,
          error: timedOut
              ? 'Processing timeout exceeded '
                  '(${perFileTimeout.inMinutes} min).'
              : error.toString(),
          stackTrace: stackTrace.toString(),
        ));
      }

      processed++;
    }

    final cancelled = cancelToken?.isCancelled ?? false;
    AppLogger.i('DATASET_COMPLETE cancelled=$cancelled '
        'processed=$processed successful=$successful '
        'failed=$failed skipped=$skipped');
    yield DatasetBatchProgress(
      totalFiles: total,
      processedFiles: processed,
      successfulFiles: successful,
      failedFiles: failed,
      skippedFiles: skipped,
      failures: List.unmodifiable(failures),
      completed: true,
      cancelled: cancelled,
    );
  }

  /// Publishes a successfully-processed staging file into the public
  /// `Music/EchoBug/<mirror>` folder via MediaStore, then deletes the staging
  /// copy. Best-effort: any failure leaves the staging file in place (so output
  /// is never lost) and is otherwise ignored — processing already succeeded.
  Future<void> _publish(
      String rootFolder, AudioFileRef source, String? stagedPath) async {
    if (stagedPath == null) return;
    try {
      final relativeDir = p.posix.join(
        'Music',
        AppConstants.datasetOutputFolder,
        MirroredOutputFileSystem.mirrorRelativeDir(rootFolder, source.path),
      );
      final published = await _mediaStore.publishToMusic(
        sourcePath: stagedPath,
        relativeDir: relativeDir,
        displayName: p.basename(stagedPath),
        mimeType: MediaStoreService.mimeForExtension(source.ext),
      );
      if (published != null) {
        await File(stagedPath).delete();
      }
    } catch (_) {
      // Best effort — keep the staged file as a fallback.
    }
  }

  /// Builds the user-facing reason a scan matched zero files, so the screen can
  /// explain it instead of silently reporting "0 files".
  String _explainNoMatch(
    DatasetScanResult scan,
    DatasetBatchConfig config,
    Set<String> extensions,
  ) {
    if (!scan.rootReadable) {
      return "Couldn't read the selected folder. On Android 11+ this needs "
          '"All files access" — grant it when prompted (or in Settings → Apps '
          '→ EchoBug → Permissions), then start again.';
    }
    final extLabel = extensions.map((e) => '.$e').join(', ');
    if (scan.audioFilesFound == 0) {
      return 'No $extLabel files were found anywhere under this folder.';
    }
    final suffixes =
        config.suffixes.where((s) => s.trim().isNotEmpty).join(', ');
    final examples = scan.sampleAudioNames.take(3).join(', ');
    return 'Found ${scan.audioFilesFound} audio file(s), but none matched your '
        'suffix(es): $suffixes. Examples found: $examples. A suffix must be the '
        'last word of the name before the extension (spaces, underscores and '
        'hyphens count the same, and case is ignored).';
  }

  DatasetAudioFile _describe(String sourcePath) {
    final dir = p.dirname(sourcePath);
    final base = p.basenameWithoutExtension(sourcePath);
    final ext = p.extension(sourcePath); // includes leading dot
    return DatasetAudioFile(
      sourcePath: sourcePath,
      outputPath: p.join(dir, '$base${AppConstants.outputSuffix}$ext'),
      folderName: p.basename(dir),
    );
  }
}
