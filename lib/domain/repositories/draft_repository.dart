import '../entities/background_profile.dart';

/// Persists the single in-progress wizard draft so edits survive app kill
/// (Calibration design §6, UX "auto-save draft").
abstract interface class DraftRepository {
  /// The saved draft, or null if none.
  BackgroundProfile? load();

  /// Saves/overwrites the current draft.
  Future<void> save(BackgroundProfile draft);

  /// Clears the draft (on Save Profile or Cancel).
  Future<void> clear();
}
