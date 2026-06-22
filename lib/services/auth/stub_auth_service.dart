import '../../core/logging/app_logger.dart';
import '../../core/result/result.dart';
import '../../domain/ports/auth_service.dart';

/// Zero-configuration [AuthService] used by default so the account feature is
/// fully exercisable without any OAuth setup or backend.
///
/// It simulates a successful Google sign-in by returning a fixed demo account
/// after a short delay (mimicking the picker round-trip). The id is stable, so
/// re-authenticating (without signing out) restores the same account and keeps
/// any profile edits. Signing out clears the stored account.
///
/// To use real Google sign-in instead, implement [AuthService] with the
/// `google_sign_in` package and register it in `auth_providers.dart`. The rest
/// of the app (repository, use cases, UI) needs no changes. Step-by-step
/// instructions: `docs/GOOGLE_SIGNIN_SETUP.md`.
class StubAuthService implements AuthService {
  const StubAuthService();

  static const _demoAccount = GoogleAccount(
    id: 'stub-google-0001',
    email: 'demo.user@gmail.com',
    displayName: 'Demo User',
    photoUrl: null,
  );

  @override
  Future<Result<GoogleAccount>> signIn() async {
    AppLogger.i('StubAuthService: simulating Google sign-in (demo account).');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const Result.ok(_demoAccount);
  }

  @override
  Future<void> signOut() async {
    AppLogger.i('StubAuthService: signed out (demo account cleared).');
  }
}
