# background_siq

A Flutter audio-processing app that applies background/filter effects to audio files using a native **FFmpeg** engine. It supports building reusable processing **profiles**, previewing the result, and exporting processed audio to the device.

- **State management / DI:** Riverpod
- **Routing:** go_router
- **Local storage (offline):** Hive CE
- **Audio engine:** `ffmpeg_kit_flutter_new` (GPL native build with `libmp3lame` / `libvorbis`)
- **Models:** Freezed + json_serializable (code-generated)
- **Targets:** Android and iOS

---

## Prerequisites

You need these installed **before** you can run the project. Versions below match what the project is currently built against.

### 1. Flutter SDK

- **Flutter `3.44.2` (stable channel)** or newer.
- This bundles the **Dart SDK** the project requires: `>=3.11.1 <4.0.0`.
- Install: https://docs.flutter.dev/get-started/install
- Verify:
  ```bash
  flutter --version
  flutter doctor
  ```
  Resolve everything `flutter doctor` flags for the platform(s) you want to build.

> **Note on FVM:** This project was developed with [FVM](https://fvm.app/). The committed `android/local.properties` points `flutter.sdk` at an FVM path. That file is **machine-specific** and is regenerated for your machine — see [Troubleshooting](#troubleshooting). FVM is optional; a normal global Flutter install works fine.

### 2. Git

Required to clone the repo. https://git-scm.com/downloads

### 3. Android toolchain (to build/run on Android)

- **Android Studio** (gives you the Android SDK, platform tools, and an emulator). https://developer.android.com/studio
- **JDK 17** — the Android build uses `sourceCompatibility`/`targetCompatibility = 17` and `jvmTarget = 17`. (Android Studio ships a compatible JDK.)
- **Android SDK** with:
  - **Min SDK 24** (Android 7.0) — required by the FFmpeg plugin.
  - A recent **compileSdk / targetSdk** (managed by Flutter; just keep the SDK updated).
- **Android NDK** — required because the app ships **native FFmpeg libraries**. Install the NDK version Flutter requests via Android Studio → *SDK Manager → SDK Tools → NDK (Side by side)*.
- Accept SDK licenses:
  ```bash
  flutter doctor --android-licenses
  ```

### 4. iOS toolchain (only if building for iOS — macOS required)

- **macOS** with **Xcode** (latest stable).
- **CocoaPods**:
  ```bash
  sudo gem install cocoapods
  ```
- Uses the GPL FFmpeg native build. iOS cannot be built on Windows/Linux.

### 5. A device or emulator/simulator

- Android emulator (via Android Studio) or a physical Android device with USB debugging enabled.
- iOS simulator or a physical iOS device (macOS only).

---

## Getting started

From a fresh clone on a new machine:

```bash
# 1. Clone
git clone <repository-url>
cd background_siq

# 2. Install Dart/Flutter dependencies
flutter pub get

# 3. Generate code (Freezed, json_serializable, Hive adapters)
#    Required — the app will NOT compile without the generated *.g.dart / *.freezed.dart files.
dart run build_runner build --delete-conflicting-outputs

# 4. (Optional) regenerate app launcher icons
dart run flutter_launcher_icons

# 5. Run it
flutter run            # picks a connected device/emulator
# or target one explicitly:
flutter devices        # list available devices
flutter run -d <device-id>
```

> **iOS only — install pods** before the first run:
> ```bash
> cd ios && pod install && cd ..
> ```

---

## Code generation

This project uses build-time code generation. You must run it after a fresh clone, after pulling changes that touch models, or whenever you edit a class annotated with `@freezed`, `@JsonSerializable`, or a Hive adapter.

```bash
# One-off build
dart run build_runner build --delete-conflicting-outputs

# Or watch and regenerate on save while developing
dart run build_runner watch --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are part of the build. If you see compile errors about missing `_$...` classes or undefined `fromJson`/`toJson`, run code generation.

---

## Building release artifacts

```bash
# Android — per-ABI APKs (armeabi-v7a, arm64-v8a) are produced (no fat universal APK)
flutter build apk --release

# Android App Bundle (recommended for Google Play; Play splits ABIs automatically)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

> **Signing:** The Android release build currently signs with the **debug** keystore so `flutter run --release` works out of the box. Before publishing, add a proper release signing config in [android/app/build.gradle.kts](android/app/build.gradle.kts).
>
> **R8 / shrinking:** Minification and resource shrinking are intentionally **disabled** for release (R8 was stripping plugin classes and crashing startup). See the comments in [android/app/build.gradle.kts](android/app/build.gradle.kts) before re-enabling.

---

## Permissions

The app reads/writes audio on shared storage and saves output to a user-visible folder.

**Android** (declared in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)):
- `READ_EXTERNAL_STORAGE` (API ≤ 32), `WRITE_EXTERNAL_STORAGE` (API ≤ 28)
- `MANAGE_EXTERNAL_STORAGE` — to create a top-level output folder on Android 11+. This is an "All files access" permission the user must grant from system settings at runtime.

---

## Project structure

```
lib/
├── core/          # constants, DI/bootstrap (Hive init), shared utilities
├── data/          # models, mappers, persistence
├── domain/        # entities (Freezed) and business logic
├── presentation/  # UI: app shell, feature screens, shared widgets
│   └── features/  # profile_wizard, profile_editor, ...
└── services/      # audio (FFmpeg processor, filter graph builder), filesystem
android/           # Android host project
ios/               # iOS host project
assets/icon/       # app launcher icon source images
test/              # unit/widget tests
```

---

## Running tests

```bash
flutter test
```

---

## Troubleshooting

- **`local.properties` points to someone else's path / SDK not found.**
  `android/local.properties` is machine-specific and auto-generated. If it has stale paths from another machine, delete it and let Flutter recreate it (run `flutter pub get` / open the `android/` folder in Android Studio), or edit it to point at your local SDKs:
  ```properties
  sdk.dir=/absolute/path/to/Android/sdk
  flutter.sdk=/absolute/path/to/flutter
  ```

- **Missing `*.g.dart` / `*.freezed.dart` or `_$...` compile errors.** Run code generation:
  `dart run build_runner build --delete-conflicting-outputs`.

- **`flutter doctor` reports NDK / licenses issues.** Install the requested NDK via Android Studio's SDK Manager and run `flutter doctor --android-licenses`.

- **Stale build / weird native errors.** Clean and rebuild:
  ```bash
  flutter clean
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```
