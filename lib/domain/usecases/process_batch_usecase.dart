import '../../core/constants/app_constants.dart';
import '../entities/audio_file_ref.dart';
import '../entities/background_profile.dart';
import '../entities/batch_progress.dart';
import '../entities/enums.dart';
import '../entities/processing_job.dart';
import 'apply_profile_usecase.dart';

/// Processes a batch of files sequentially with one profile (SRS §15).
///
/// Reuses [ApplyProfileUseCase] per file, so each file gets the same
/// validation, output-path resolution, and history recording as a single run.
/// Input is capped at [AppConstants.maxBatchFiles]; a failure on one file does
/// not abort the rest.
class ProcessBatchUseCase {
  const ProcessBatchUseCase(this._apply);

  final ApplyProfileUseCase _apply;

  Stream<BatchProgress> call(
    List<AudioFileRef> files,
    BackgroundProfile profile,
  ) async* {
    final batch = files.take(AppConstants.maxBatchFiles).toList();
    final results = <BatchFileResult>[];

    for (var i = 0; i < batch.length; i++) {
      ProcessingJob? lastJob;
      await for (final job in _apply.call(batch[i], profile)) {
        lastJob = job;
        yield BatchProgress(
          total: batch.length,
          currentIndex: i,
          currentFileProgress: job.progress,
          currentStage: job.stage,
          completed: List.unmodifiable(results),
        );
      }

      final ok = lastJob?.stage == JobStage.completed;
      results.add(BatchFileResult(
        file: batch[i],
        status: ok ? JobStatus.success : JobStatus.failed,
        outputPath: lastJob?.outputPath,
        error: lastJob?.errorMessage,
      ));
    }

    yield BatchProgress(
      total: batch.length,
      currentIndex: batch.length,
      currentFileProgress: 1,
      currentStage: JobStage.completed,
      completed: List.unmodifiable(results),
      done: true,
    );
  }
}
