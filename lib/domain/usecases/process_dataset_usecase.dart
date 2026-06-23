import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
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
  }) async* {
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
      }
      final profile = resolved[sp.profileId];
      if (profile != null) profileBySuffix[sp.suffix] = profile;
    }

    if (profileBySuffix.isEmpty) {
      yield DatasetBatchProgress(
        completed: true,
        failures: [
          DatasetFileFailure(
            filePath: config.rootFolder,
            error: firstError ?? 'No profile could be resolved for any suffix.',
          ),
        ],
      );
      return;
    }

    // --- Discover matching files. ---
    yield const DatasetBatchProgress(scanning: true);

    final List<String> paths;
    if (onlyPaths != null) {
      paths = onlyPaths;
    } else {
      paths = await _scanner
          .scan(
            rootFolder: config.rootFolder,
            suffixes: config.suffixes,
            extensions: extensions,
          )
          .toList();
    }

    final queue = paths.map(_describe).toList();
    final total = queue.length;

    if (total == 0) {
      yield const DatasetBatchProgress(completed: true);
      return;
    }

    yield DatasetBatchProgress(totalFiles: total);

    // Build the engine for this run; its file system mirrors the source tree
    // under the public output root (e.g. Music/EchoBug/<rootName>/...).
    final apply = await _buildApply(config.rootFolder);

    // --- Process sequentially. ---
    var processed = 0;
    var successful = 0;
    var failed = 0;
    var skipped = 0;
    final failures = <DatasetFileFailure>[];

    for (final file in queue) {
      if (cancelToken?.isCancelled ?? false) break;

      final fileName = p.basename(file.sourcePath);

      yield DatasetBatchProgress(
        totalFiles: total,
        processedFiles: processed,
        successfulFiles: successful,
        failedFiles: failed,
        skippedFiles: skipped,
        currentFile: fileName,
        currentFolder: file.folderName,
        currentFileProgress: 0,
        failures: List.unmodifiable(failures),
      );

      // Skip files that vanished between discovery and processing.
      if (!await _fileSystem.exists(file.sourcePath)) {
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
        failed++;
        processed++;
        failures.add(DatasetFileFailure(
          filePath: file.sourcePath,
          fileName: fileName,
          error: suffix == null
              ? 'No configured suffix matched this file.'
              : 'No profile available for suffix "$suffix".',
        ));
        continue;
      }

      final source = AudioFileRef(
        path: file.sourcePath,
        name: fileName,
        ext: p.extension(file.sourcePath).replaceFirst('.', '').toLowerCase(),
      );

      try {
        ProcessingJob? lastJob;
        await for (final job in apply.call(source, profile)) {
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
            failures: List.unmodifiable(failures),
          );
        }

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
        failed++;
        failures.add(DatasetFileFailure(
          filePath: file.sourcePath,
          fileName: fileName,
          error: error.toString(),
          stackTrace: stackTrace.toString(),
        ));
      }

      processed++;
    }

    final cancelled = cancelToken?.isCancelled ?? false;
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
