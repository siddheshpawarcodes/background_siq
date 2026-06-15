import '../../core/result/result.dart';
import '../entities/audio_meta.dart';
import '../entities/process_request.dart';

/// The audio engine seam (SRS §7.4, §10.1). The domain depends only on this;
/// the FFmpeg backend (mobile fork) implements it in the services layer.
abstract interface class AudioProcessorPort {
  /// Runs the full pipeline, emitting progress until completion.
  /// The terminal event carries [JobStage.completed] or [JobStage.failed].
  Stream<ProcessingProgress> process(ProcessRequest request);

  /// Renders a short preview clip and returns its temp path.
  Future<Result<String>> preview(ProcessRequest request);

  /// Reads technical metadata (duration, channels, codec) for a file.
  Future<Result<AudioMeta>> probe(String path);

  /// Cancels the running job, if any.
  Future<void> cancel(String jobId);
}
