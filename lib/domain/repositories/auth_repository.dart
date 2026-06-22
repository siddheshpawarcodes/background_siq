import '../../core/result/result.dart';
import '../entities/auth_user.dart';

/// Persistence + session contract for the signed-in account (SRS §7.3).
///
/// Sign-in is optional: the app is fully usable signed out, so [current] and
/// the [watch] stream emit `null` until the user signs in. All profile data is
/// stored locally — there is no backend.
abstract interface class AuthRepository {
  /// The currently signed-in user, or `null` when signed out. Synchronous read
  /// for guards/initial UI state.
  AuthUser? get current;

  /// Emits the current user (or `null`) and again on every change
  /// (sign-in, sign-out, profile edit).
  Stream<AuthUser?> watch();

  /// Runs the Google sign-in flow and persists the resulting account. A
  /// returning user keeps their previously-edited profile fields.
  Future<Result<AuthUser>> signInWithGoogle();

  /// Signs out and clears the stored account.
  Future<void> signOut();

  /// Persists edited profile fields for the signed-in user.
  Future<void> updateProfile(AuthUser user);
}
