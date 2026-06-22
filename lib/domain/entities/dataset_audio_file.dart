/// A single audio file discovered by the dataset scanner that matched the
/// configured suffix and is queued for processing.
///
/// [outputPath] is a *nominal* destination only (for display). The actual
/// written path is resolved at write time by the mirroring file-system service
/// (mirrored under `Music/EchoBug/`, `_echobug` suffix, with `_1`/`_2`
/// collision-avoidance), and reported in the per-file result.
class DatasetAudioFile {
  const DatasetAudioFile({
    required this.sourcePath,
    required this.outputPath,
    required this.folderName,
  });

  /// Absolute path of the source audio file.
  final String sourcePath;

  /// Nominal output path (same folder as source, `_EchoBug` appended).
  final String outputPath;

  /// Name of the immediate parent folder (used for progress display).
  final String folderName;
}
