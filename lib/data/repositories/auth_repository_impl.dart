import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/ports/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/user_mapper.dart';
import '../models/user_model.dart';

/// Hive-backed implementation of [AuthRepository] (SRS §7.3).
///
/// Combines the [AuthService] OAuth flow with a single-row Hive box holding the
/// account + its editable profile. Everything is local — no backend.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required Box<UserModel> box, required AuthService service})
      : _box = box,
        _service = service;

  final Box<UserModel> _box;
  final AuthService _service;

  AuthUser? _read() => _box.get(AppConstants.userKey)?.toEntity();

  @override
  AuthUser? get current => _read();

  @override
  Stream<AuthUser?> watch() async* {
    yield _read();
    yield* _box.watch().map((_) => _read());
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    final result = await _service.signIn();
    return result.map((account) {
      // A returning user keeps the profile fields they previously edited;
      // only the Google-supplied identity is refreshed.
      final existing = _read();
      final isSameAccount = existing != null && existing.id == account.id;
      final user = AuthUser(
        id: account.id,
        email: account.email,
        googleDisplayName: account.displayName,
        googlePhotoUrl: account.photoUrl,
        displayNameOverride: isSameAccount ? existing.displayNameOverride : null,
        photoPath: isSameAccount ? existing.photoPath : null,
        phone: isSameAccount ? existing.phone : null,
        company: isSameAccount ? existing.company : null,
        role: isSameAccount ? existing.role : null,
        signedInAt: DateTime.now(),
      );
      _box.put(AppConstants.userKey, user.toModel());
      return user;
    });
  }

  @override
  Future<void> signOut() async {
    await _service.signOut();
    await _box.delete(AppConstants.userKey);
  }

  @override
  Future<void> updateProfile(AuthUser user) async {
    await _box.put(AppConstants.userKey, user.toModel());
  }
}
