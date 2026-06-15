import 'package:freezed_annotation/freezed_annotation.dart';

import 'audio_file_ref.dart';
import 'background_profile.dart';
import 'enums.dart';

part 'processing_job.freezed.dart';

/// Transient state driving the processing progress UI (SRS §7.1, §11.2).
@freezed
abstract class ProcessingJob with _$ProcessingJob {
  const factory ProcessingJob({
    required String id,
    required AudioFileRef source,
    required BackgroundProfile profile,
    @Default(JobStage.preparing) JobStage stage,
    @Default(0.0) double progress, // 0..1
    String? outputPath,
    String? errorMessage,
  }) = _ProcessingJob;
}
