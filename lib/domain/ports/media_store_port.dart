/// Publishes a processed file into the device's public media storage so it is
/// visible to other apps (e.g. the Music app and file managers).
///
/// On Android this is backed by MediaStore. On platforms without a public media
/// store the implementation returns `null`, and the caller keeps the file in
/// app-private storage instead.
abstract class MediaStorePort {
  /// Copies the file at [sourcePath] into the public Music collection at
  /// [relativeDir] (e.g. `Music/EchoBug/music data/Amalki`) under [displayName]
  /// with the given [mimeType].
  ///
  /// Returns a user-facing location (a content URI or absolute path) on
  /// success, or `null` when publishing is unavailable or fails.
  Future<String?> publishToMusic({
    required String sourcePath,
    required String relativeDir,
    required String displayName,
    required String mimeType,
  });
}
