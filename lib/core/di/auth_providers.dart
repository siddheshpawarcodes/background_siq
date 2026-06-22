import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/ports/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../services/auth/stub_auth_service.dart';
import 'repository_providers.dart';

/// Dependency injection for the optional Google account feature (SRS §9).
///
/// The OAuth provider is isolated behind [authServiceProvider]; swap the
/// default [StubAuthService] for a real `google_sign_in`-backed implementation
/// here and nothing else changes (see `docs/GOOGLE_SIGNIN_SETUP.md`).

/// The OAuth provider. Default: a zero-config stub that simulates Google.
final authServiceProvider = Provider<AuthService>(
  (ref) => const StubAuthService(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    box: ref.watch(appBoxesProvider).user,
    service: ref.watch(authServiceProvider),
  ),
);

/// The signed-in user (or `null` when signed out) — watched across the UI.
final currentUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).watch(),
);

// --- Auth use cases (SRS §7.2) ---

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.watch(authRepositoryProvider)),
);
