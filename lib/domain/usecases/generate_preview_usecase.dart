import '../../core/result/result.dart';
import '../entities/audio_file_ref.dart';
import '../entities/background_profile.dart';
import '../entities/process_request.dart';
import '../ports/audio_processor_port.dart';
import '../ports/file_system_port.dart';

/// Renders a local preview applying the full profile (SRS §10.5). The whole
/// source is rendered (no trim) so the user can audition the entire result.
class GeneratePreviewUseCase {
  GeneratePreviewUseCase({
    required AudioProcessorPort processor,
    required FileSystemPort fileSystem,
    required String Function() idGenerator,
  })  : _processor = processor,
        _fileSystem = fileSystem,
        _newId = idGenerator;

  final AudioProcessorPort _processor;
  final FileSystemPort _fileSystem;
  final String Function() _newId;

  String? _activeJobId;

  Future<Result<String>> call(AudioFileRef source, BackgroundProfile profile) async {
    final jobId = _newId();
    // Unique per render so a fresh preview never overwrites the file the player
    // is still holding from the previous render.
    final outputPath = await _fileSystem.previewPath(source.ext, token: jobId);
    _activeJobId = jobId;
    final request = ProcessRequest(
      jobId: jobId,
      source: source,
      profile: profile,
      outputPath: outputPath,
    );
    return _processor.preview(request);
  }

  /// Cancels the most recent preview render, if still running (design §7).
  Future<void> cancelActive() async {
    final id = _activeJobId;
    if (id != null) await _processor.cancel(id);
  }

  /// Deletes leftover preview renders from the temp dir (e.g. on leaving the
  /// calibration screen) so nothing lingers after the session.
  Future<void> clearPreviews() => _fileSystem.clearPreviews();
}
