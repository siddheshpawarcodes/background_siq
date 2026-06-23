import 'suffix_profile.dart';

/// Configuration for a Dataset Batch Processing run.
///
/// This feature is independent of the regular (manual, up-to-50) batch flow.
/// The user selects a [rootFolder] and one or more [suffixProfiles] — each
/// pairing a filename suffix (e.g. `_eng`, `_hin`, `_san`) with the profile
/// (and thus the background music) to apply to files matching that suffix.
/// This lets a single run give each suffix its own background music.
class DatasetBatchConfig {
  const DatasetBatchConfig({
    required this.rootFolder,
    required this.suffixProfiles,
  });

  /// Absolute path of the dataset root directory to traverse recursively.
  final String rootFolder;

  /// Suffix → profile pairings. A file matches when it ends with
  /// `<suffix>.<ext>` for one of these suffixes, and the paired profile is
  /// applied to it. When a name matches more than one suffix, the longest
  /// suffix wins (resolved by [DatasetFileScanner.matchedSuffix]).
  final List<SuffixProfile> suffixProfiles;

  /// All matched suffixes, derived from [suffixProfiles] (for the scanner).
  List<String> get suffixes =>
      suffixProfiles.map((sp) => sp.suffix).toList(growable: false);

  /// Lookup from suffix to profile id.
  Map<String, String> get profileIdBySuffix =>
      {for (final sp in suffixProfiles) sp.suffix: sp.profileId};

  DatasetBatchConfig copyWith({
    String? rootFolder,
    List<SuffixProfile>? suffixProfiles,
  }) =>
      DatasetBatchConfig(
        rootFolder: rootFolder ?? this.rootFolder,
        suffixProfiles: suffixProfiles ?? this.suffixProfiles,
      );
}
