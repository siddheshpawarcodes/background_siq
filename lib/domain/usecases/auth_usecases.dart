import '../../core/result/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Sign in (or sign up) with Google (SRS §7.2). First sign-in creates the
/// local account; subsequent sign-ins restore it.
class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthUser>> call() => _repo.signInWithGoogle();
}

class SignOutUseCase {
  const SignOutUseCase(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.signOut();
}

/// Persists user-edited profile fields (display name, photo, phone, company,
/// role). Identity fields from Google are left untouched.
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repo);
  final AuthRepository _repo;

  Future<void> call(AuthUser user) => _repo.updateProfile(user);
}
