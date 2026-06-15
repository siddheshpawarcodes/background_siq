import '../../core/result/result.dart';
import '../entities/audio_file_ref.dart';

/// File-system operations the domain needs, kept platform-agnostic (SRS §7.4).
abstract interface class FileSystemPort {
  /// Resolves the output path for a processed file: `<base>_WBM.<sourceExt>`
  /// (mirror-source extension, SRS §3.1). Prefers [preferredDir] when writable,
  /// otherwise falls back to the app output folder. Guarantees a unique name.
  Future<Result<String>> resolveOutputPath({
    required AudioFileRef source,
    String? preferredDir,
  });

  /// Temp path for a rendered preview clip with the given [extension].
  Future<String> previewPath(String extension);

  /// Whether [path] exists and is readable.
  Future<bool> exists(String path);
}
