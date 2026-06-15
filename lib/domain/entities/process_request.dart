import 'package:freezed_annotation/freezed_annotation.dart';

import 'audio_file_ref.dart';
import 'background_profile.dart';
import 'enums.dart';

part 'process_request.freezed.dart';

/// A single unit of work for the audio engine (SRS §10). Designed so batch
/// mode (SRS §15) can enqueue many requests without changing the engine.
@freezed
abstract class ProcessRequest with _$ProcessRequest {
  const factory ProcessRequest({
    required String jobId,
    required AudioFileRef source,
    required BackgroundProfile profile,
    required String outputPath,
    /// When set, only this leading slice is rendered (preview — SRS §10.5).
    Duration? trim,
  }) = _ProcessRequest;
}

/// Progress emitted as a job runs (SRS §11.2).
@freezed
abstract class ProcessingProgress with _$ProcessingProgress {
  const factory ProcessingProgress({
    required JobStage stage,
    required double progress, // 0..1
  }) = _ProcessingProgress;
}
