# Google Sign-In setup (no backend required)

The account feature ships with a **stub** sign-in provider so it works out of the
box with zero configuration. Identity is verified by Google **on the device** —
there is **no app-owned server** to deploy. The only setup is registering a free
OAuth client in Google Cloud. All profile data is stored locally in Hive.

## Architecture (where to plug in)

The OAuth flow sits behind one port, so swapping stub → real changes a single
provider:

- Port: `lib/domain/ports/auth_service.dart` — `AuthService` + `GoogleAccount`
- Stub (default): `lib/services/auth/stub_auth_service.dart` — `StubAuthService`
- DI: `lib/core/di/auth_providers.dart` — `authServiceProvider`

The repository, use cases, login screen, edit-profile screen, and Settings
section consume only `AuthService` / `AuthRepository`, so **none of them change**.

## Steps to enable real Google sign-in

### 1. Add the package

```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.2.1   # pin to the version whose API matches the code below
```

Run `flutter pub get`.

### 2. Register OAuth clients in Google Cloud Console (free, no server)

Create a project at <https://console.cloud.google.com/>, configure the OAuth
consent screen, then create credentials:

- **Android** — OAuth client of type *Android*. Provide the application id
  (`com.example.background_siq`, see `android/app/build.gradle.kts`) and the
  signing-certificate **SHA-1**. Get it with:
  ```bash
  cd android && ./gradlew signingReport   # use the SHA-1 from the debug + release variants
  ```
  Register both your debug SHA-1 and your release/upload SHA-1.
- **iOS** — OAuth client of type *iOS* using the bundle id from
  `ios/Runner.xcodeproj`. Add the reverse client id as a URL scheme:
  ```xml
  <!-- ios/Runner/Info.plist -->
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
      </array>
    </dict>
  </array>
  ```
- **Web server client id** (optional) — only needed if you later add a backend
  that verifies the `idToken`. Not required for on-device sign-in.

### 3. Implement the real `AuthService`

Create `lib/services/auth/google_auth_service.dart`:

```dart
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/result/result.dart';
import '../../domain/ports/auth_service.dart';

class GoogleAuthService implements AuthService {
  GoogleAuthService() : _google = GoogleSignIn(scopes: const ['email']);

  final GoogleSignIn _google;

  @override
  Future<Result<GoogleAccount>> signIn() async {
    try {
      final account = await _google.signIn();
      if (account == null) return const Result.err(SignInCancelledFailure());
      return Result.ok(GoogleAccount(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      ));
    } catch (e) {
      AppLogger.e('Google sign-in failed', e);
      return Result.err(SignInFailure(debugDetail: e.toString()));
    }
  }

  @override
  Future<void> signOut() => _google.signOut();
}
```

> The `google_sign_in` API changed across major versions (v6 uses
> `signIn()`/`GoogleSignInAccount`; v7 uses `initialize()`/`authenticate()`).
> Match the snippet to the version you pin, or update accordingly.

### 4. Flip the provider

```dart
// lib/core/di/auth_providers.dart
final authServiceProvider = Provider<AuthService>(
  (ref) => GoogleAuthService(),   // was: const StubAuthService()
);
```

Also remove the `_DemoNotice` banner in
`lib/presentation/features/auth/login_screen.dart`.

That's it — sign-in, the Settings Account section, and Edit Profile all keep
working unchanged.
