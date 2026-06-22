import '../../core/result/result.dart';

/// The raw identity returned by an OAuth provider (Google). This is the
/// provider's view of the account — the app layers its own editable profile
/// on top (see [AuthUser]).
class GoogleAccount {
  const GoogleAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Stable, provider-issued account id (the Google `sub`).
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// Port for the Google sign-in flow (SRS §9 — hexagonal boundary).
///
/// Implementations perform the client-side OAuth handshake; no app-owned
/// backend is required. The default wiring is [StubAuthService] (works with
/// zero configuration); swap in a real `google_sign_in`-backed implementation
/// by adding OAuth client ids — see `docs/GOOGLE_SIGNIN_SETUP.md`.
abstract interface class AuthService {
  /// Launches the Google account picker / consent flow.
  ///
  /// Returns the chosen [GoogleAccount], a [SignInCancelledFailure] when the
  /// user dismisses the picker, or a [SignInFailure] on any other error.
  Future<Result<GoogleAccount>> signIn();

  /// Clears the provider session so the next [signIn] re-prompts.
  Future<void> signOut();
}
