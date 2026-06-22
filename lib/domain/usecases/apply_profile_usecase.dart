import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../entities/audio_file_ref.dart';
import '../entities/background_profile.dart';
import '../entities/enums.dart';
import '../entities/history_entry.dart';
import '../entities/process_request.dart';
import '../entities/processing_job.dart';
import '../ports/audio_processor_port.dart';
import '../ports/file_system_port.dart';
import '../repositories/history_repository.dart';
import '../repositories/settings_repository.dart';

/// Orchestrates the full Apply flow (SRS §7.2, §11.2): pre-flight validation →
/// output path resolution → run the engine → record history. Emits a
/// [ProcessingJob] for every progress update so the UI can render stage + %.
class ApplyProfileUseCase {
  ApplyProfileUseCase({
    required AudioProcessorPort processor,
    required FileSystemPort fileSystem,
    required SettingsRepository settings,
    required HistoryRepository history,
    required String Function() idGenerator,
    bool recordHistory = true,
  })  : _processor = processor,
        _fileSystem = fileSystem,
        _settings = settings,
        _history = history,
        _newId = idGenerator,
        _shouldRecordHistory = recordHistory;

  final AudioProcessorPort _processor;
  final FileSystemPort _fileSystem;
  final SettingsRepository _settings;
  final HistoryRepository _history;
  final String Function() _newId;

  /// When false, this use case skips writing a [HistoryEntry] per file. Used by
  /// the Dataset Batch flow, which has its own results view and writes output to
  /// transient staging paths that would make per-file history entries useless.
  final bool _shouldRecordHistory;

  Stream<ProcessingJob> call(AudioFileRef source, BackgroundProfile profile) async* {
    final jobId = _newId();
    var job = ProcessingJob(id: jobId, source: source, profile: profile);

    // --- Pre-flight validation (SRS §13.3) ---
    if (!AppConstants.supportedInputExtensions.contains(source.ext.toLowerCase())) {
      yield job.copyWith(
          stage: JobStage.failed, errorMessage: const UnsupportedFormatFailure().message);
      return;
    }
    if (!await _fileSystem.exists(source.path)) {
      yield job.copyWith(
          stage: JobStage.failed, errorMessage: const FileNotFoundFailure().message);
      return;
    }

    final settings = await _settings.get();
    final outputResult = await _fileSystem.resolveOutputPath(
      source: source,
      preferredDir: settings.defaultExportFolder,
    );
    final outputPath = outputResult.valueOrNull;
    if (outputPath == null) {
      yield job.copyWith(
          stage: JobStage.failed, errorMessage: outputResult.failureOrNull!.message);
      return;
    }

    final request = ProcessRequest(
      jobId: jobId,
      source: source,
      profile: profile,
      outputPath: outputPath,
    );

    final stopwatch = Stopwatch()..start();
    try {
      await for (final progress in _processor.process(request)) {
        job = job.copyWith(stage: progress.stage, progress: progress.progress);
        if (progress.stage == JobStage.completed) {
          job = job.copyWith(outputPath: outputPath, progress: 1);
        }
        yield job;
      }
      stopwatch.stop();
      if (_shouldRecordHistory) {
        await _recordHistory(
            job, profile, outputPath, stopwatch.elapsed, JobStatus.success);
      }
    } catch (error) {
      stopwatch.stop();
      final message = error is Failure ? error.message : const UnknownFailure().message;
      job = job.copyWith(stage: JobStage.failed, errorMessage: message);
      yield job;
      if (_shouldRecordHistory) {
        await _recordHistory(
            job, profile, outputPath, stopwatch.elapsed, JobStatus.failed);
      }
    }
  }

  Future<void> _recordHistory(
    ProcessingJob job,
    BackgroundProfile profile,
    String outputPath,
    Duration elapsed,
    JobStatus status,
  ) async {
    await _history.add(HistoryEntry(
      id: job.id,
      sourcePath: job.source.path,
      outputPath: outputPath,
      date: DateTime.now(),
      profileName: profile.name,
      processingTime: elapsed,
      status: status,
    ));
  }
}
