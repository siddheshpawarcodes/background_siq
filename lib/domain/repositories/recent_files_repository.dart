import '../entities/audio_file_ref.dart';

/// Persistence contract for recently-picked source files (SRS §7.3).
abstract interface class RecentFilesRepository {
  /// Most-recent-first list of recent files.
  Future<List<AudioFileRef>> recent();

  /// Emits recent files on every change.
  Stream<List<AudioFileRef>> watch();

  /// Records [file] as most-recently used (de-duplicated by path).
  Future<void> push(AudioFileRef file);

  /// Clears the recent list.
  Future<void> clear();
}
