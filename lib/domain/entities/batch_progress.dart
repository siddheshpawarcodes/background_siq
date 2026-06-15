import 'package:freezed_annotation/freezed_annotation.dart';

import 'audio_file_ref.dart';
import 'enums.dart';

part 'batch_progress.freezed.dart';

/// Outcome for one file within a batch.
@freezed
abstract class BatchFileResult with _$BatchFileResult {
  const factory BatchFileResult({
    required AudioFileRef file,
    required JobStatus status,
    String? outputPath,
    String? error,
  }) = _BatchFileResult;
}

/// Progress of a batch run (SRS §15). Emitted continuously while a batch of up
/// to 50 files is processed sequentially.
@freezed
abstract class BatchProgress with _$BatchProgress {
  const factory BatchProgress({
    required int total,
    required int currentIndex, // 0-based index of the file in progress
    @Default(0.0) double currentFileProgress, // 0..1
    @Default(JobStage.preparing) JobStage currentStage,
    @Default([]) List<BatchFileResult> completed,
    @Default(false) bool done,
  }) = _BatchProgress;

  const BatchProgress._();

  /// Overall completion across the whole batch, 0..1.
  double get overall {
    if (total == 0) return 0;
    return ((currentIndex + currentFileProgress) / total).clamp(0.0, 1.0);
  }

  int get successCount =>
      completed.where((r) => r.status == JobStatus.success).length;
  int get failureCount =>
      completed.where((r) => r.status == JobStatus.failed).length;
}
