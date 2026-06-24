/// Pairs a filename suffix with the id of the [BackgroundProfile] (and thus the
/// background music) to apply to files matching that suffix.
///
/// A Dataset Batch run carries one of these per suffix, so different suffixes
/// (e.g. `_eng`, `_hin`, `_san`) can each get their own background music in a
/// single run.
class SuffixProfile {
  const SuffixProfile({
    required this.suffix,
    required this.profileId,
    this.coverImagePath,
  });

  /// Filename suffix to match, e.g. `_eng`. Exactly what the user typed.
  final String suffix;

  /// Id of the [BackgroundProfile] applied to files matching [suffix].
  final String profileId;

  /// Optional cover-art image (thumbnail) to embed in the exports of files
  /// matching [suffix]. Chosen alongside the backdrop on the setup screen, so
  /// each suffix can carry its own thumbnail. Null means no cover art.
  final String? coverImagePath;

  SuffixProfile copyWith({
    String? suffix,
    String? profileId,
    String? coverImagePath,
  }) =>
      SuffixProfile(
        suffix: suffix ?? this.suffix,
        profileId: profileId ?? this.profileId,
        coverImagePath: coverImagePath ?? this.coverImagePath,
      );

  @override
  bool operator ==(Object other) =>
      other is SuffixProfile &&
      other.suffix == suffix &&
      other.profileId == profileId &&
      other.coverImagePath == coverImagePath;

  @override
  int get hashCode => Object.hash(suffix, profileId, coverImagePath);

  @override
  String toString() =>
      'SuffixProfile($suffix -> $profileId, cover: $coverImagePath)';
}
