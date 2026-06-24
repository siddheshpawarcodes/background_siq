import '../../core/result/result.dart';
import '../entities/audio_file_ref.dart';

/// File-system operations the domain needs, kept platform-agnostic (SRS §7.4).
abstract interface class FileSystemPort {
  /// Resolves the output path for a processed file: `<base>_EchoBug.<sourceExt>`
  /// (mirror-source extension, SRS §3.1). Prefers [preferredDir] when writable,
  /// otherwise falls back to the app output folder. Guarantees a unique name.
  Future<Result<String>> resolveOutputPath({
    required AudioFileRef source,
    String? preferredDir,
  });

  /// Temp path for a rendered preview clip with the given [extension]. A
  /// distinct [token] yields a distinct filename so a fresh render never
  /// overwrites a clip the audio player still holds open; stale preview files
  /// are pruned so the temp dir doesn't grow.
  Future<String> previewPath(String extension, {String? token});

  /// Deletes any leftover preview renders from the temp dir, e.g. when the
  /// calibration screen closes. Best-effort; never throws.
  Future<void> clearPreviews();

  /// Whether [path] exists and is readable.
  Future<bool> exists(String path);
}
