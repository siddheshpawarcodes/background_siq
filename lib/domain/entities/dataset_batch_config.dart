/// Configuration for a Dataset Batch Processing run.
///
/// This feature is independent of the regular (manual, up-to-50) batch flow.
/// The user selects a [rootFolder], one or more filename suffixes to match
/// ([selectedSuffixes], e.g. `_eng`, `_hin`, `_san`), and the [profileId] to
/// apply to every matching file.
class DatasetBatchConfig {
  const DatasetBatchConfig({
    required this.rootFolder,
    required this.selectedSuffixes,
    required this.profileId,
  });

  /// Absolute path of the dataset root directory to traverse recursively.
  final String rootFolder;

  /// Filename suffixes to match; a file matches when it ends with
  /// `<suffix>.<ext>` for *any* of these. e.g. `_eng`, `_hin`, `_san`.
  final List<String> selectedSuffixes;

  /// Id of the [BackgroundProfile] to apply to each matching file.
  final String profileId;

  DatasetBatchConfig copyWith({
    String? rootFolder,
    List<String>? selectedSuffixes,
    String? profileId,
  }) =>
      DatasetBatchConfig(
        rootFolder: rootFolder ?? this.rootFolder,
        selectedSuffixes: selectedSuffixes ?? this.selectedSuffixes,
        profileId: profileId ?? this.profileId,
      );
}
