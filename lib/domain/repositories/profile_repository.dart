import '../../core/result/result.dart';
import '../entities/background_profile.dart';

/// Persistence contract for background-music profiles (SRS §7.3).
abstract interface class ProfileRepository {
  /// Emits the full profile list on every change.
  Stream<List<BackgroundProfile>> watchAll();

  /// One-shot read of all profiles.
  Future<List<BackgroundProfile>> getAll();

  /// Returns the profile by id, or a [ProfileNotFoundFailure].
  Future<Result<BackgroundProfile>> getById(String id);

  /// Synchronous read from the local store (null if absent). Convenient for
  /// seeding form state; the backing store is local so this never blocks on IO.
  BackgroundProfile? getByIdSync(String id);

  /// Inserts or updates a profile.
  Future<Result<void>> save(BackgroundProfile profile);

  /// Deletes the profile with [id].
  Future<Result<void>> delete(String id);

  /// Creates a copy of [id] with a new id and a "(copy)" name.
  Future<Result<BackgroundProfile>> duplicate(String id);
}
