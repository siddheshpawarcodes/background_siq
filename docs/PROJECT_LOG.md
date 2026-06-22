# EchoBug — Project Log, Architecture & Change History

**App:** EchoBug — `echobug`
**Purpose:** 100% offline Flutter app that mixes a voice recording with background music and exports a broadcast-quality file, driven by reusable, calibratable profiles.
**Platforms:** Android + iOS (mobile only; iOS code-ready, not yet built — no device). Desktop out of scope.
**Last updated:** 2026-06-22

> Companion docs: [SRS_AND_ARCHITECTURE.md](SRS_AND_ARCHITECTURE.md) (full SRS + 10-phase roadmap + decisions) · [PROFILE_CALIBRATION_DESIGN.md](PROFILE_CALIBRATION_DESIGN.md) (calibration feature design).

---

## 1. What the app does

Primary flow: **open → pick a voice file → pick a profile → Apply → `meeting.mp3` becomes `meeting_EchoBug.mp3`** (mirror-source extension), with the full 9-step DSP pipeline applied. Also: batch (up to 50 files), 15-second live preview, profile creation/calibration wizard, processing history, and settings — all offline, no network/cloud/API/subscription.

### 9-step audio pipeline (single FFmpeg invocation)
1. Import voice → 2. Noise reduction (`afftdn`, Off/Mild/Medium/Aggressive) → 3. Voice enhancement (`highpass`+`equalizer`+`acompressor`) → 4. Music mix (`volume`+`amix`) → 5. Side-chain ducking (`sidechaincompress`, Off/Light/Medium/Strong) → 6. Fade in (`afade`) → 7. Fade out (`afade`) → 8. Loudness normalization (`loudnorm`, **−16 LUFS / −1.5 dBTP / LRA 11**) → 9. Export (encoder chosen by output container).

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter 3.41 / Dart 3.11 | |
| State mgmt / DI | **Riverpod** (`flutter_riverpod` 2.6) | manual providers (no codegen) |
| Local DB | **Hive CE** (`hive_ce`, `hive_ce_flutter`, `hive_ce_generator`) | maintained fork; original `hive` is abandoned & SDK-incompatible |
| Audio engine | **`ffmpeg_kit_flutter_new` 4.2.1** | native build = `ffmpeg-kit-flutter-android-full-gpl-8.0.0` (all codecs bundled) |
| Models | **freezed 3.x** + `json_serializable` | entities immutable; profile has JSON for export/import |
| Routing | `go_router` 14 | bottom-nav shell + pushed routes |
| Files/paths | `file_picker`, `path_provider`, `path`, `permission_handler` | |
| Playback | `just_audio` | preview playback |
| Open/share | `open_filex`, `share_plus` 12 | open output, export profiles |
| Logging/ids | `logger`, `uuid` | |

**Android config:** `minSdk = 24` (FFmpeg fork requirement) in `android/app/build.gradle.kts`. Release currently signs with the debug keystore (fine for sideloading; replace before Play Store).

---

## 3. Architecture (Clean Architecture + ports)

Dependencies point inward. Presentation → Domain ← Data; services implement domain **ports**.

```
lib/
├── core/                     # cross-cutting
│   ├── constants/            # AppConstants (formats, _EchoBug suffix, loudness, box names, maxBatchFiles=50)
│   ├── errors/               # sealed Failure hierarchy (+ ValidationFailure)
│   ├── result/               # Result<T> = Ok | Err
│   ├── theme/                # Material 3 light/dark + Spacing tokens
│   ├── logging/              # AppLogger (toggle via settings)
│   └── di/                   # bootstrap (Hive init/seed) + provider wiring
├── domain/                   # pure, no Flutter/IO
│   ├── entities/             # BackgroundProfile, AudioFileRef, ProcessingJob, HistoryEntry,
│   │                         #   AppSettings, AudioMeta, ProcessRequest/Progress, BatchProgress, enums,
│   │                         #   DatasetBatchConfig/AudioFile/Progress/FileFailure
│   ├── repositories/         # interfaces: Profile, Settings, History, RecentFiles, Draft
│   ├── ports/                # AudioProcessorPort, FileSystemPort
│   └── usecases/             # Apply, Preview, Batch, ProcessDataset, profile CRUD, settings, transfer (export/import)
├── data/
│   ├── models/               # Hive DTOs (@HiveType) + generated adapters
│   ├── mappers/              # model ⇄ entity (enum-by-index, safe)
│   ├── datasources/          # AppBoxes (opened Hive boxes)
│   ├── repositories/         # *Impl
│   └── seed/                 # 6 default profiles
├── services/
│   ├── audio/                # FfmpegAudioProcessor (port impl), FilterGraphBuilder, StageTimeline
│   ├── filesystem/           # FilePickService, FileSystemService (output path resolution)
│   ├── dataset/              # DatasetFileScanner, DatasetBatchCancellationToken, SameFolderFileSystem (FileSystemPort decorator)
│   ├── maintenance/          # clear cache + reset app
│   ├── platform/             # OpenFileService
│   └── profile/              # ProfileTransferService (export/import)
└── presentation/
    ├── app.dart, router/     # MaterialApp.router + go_router
    ├── shared/               # MainShell (nav), AudioFileCard
    └── features/             # home, processing, profiles, profile_wizard, batch, dataset_batch, history, settings
```

### Key patterns
- **Ports/adapters:** the domain knows only `AudioProcessorPort`/`FileSystemPort`. Swapping the FFmpeg backend or adding desktop later needs no domain/UI change.
- **No business logic in widgets:** validation/orchestration live in use cases; widgets read providers + call use cases.
- **Result<T> over exceptions:** layers return `Ok`/`Err(Failure)`; UI maps `Failure.message` to friendly text.
- **Single-pass FFmpeg:** the whole pipeline is one `filter_complex` (faster, no temp files); progress derived from the statistics callback ÷ probed duration.

---

## 4. Data model & storage

**Hive boxes:** `profiles` (typeId 0), `settings` (1), `history` (2), `recent_files` (3), `profile_draft` (ProfileModel, key `current`).

**`BackgroundProfile`** (entity): id, name, **description**, musicFilePath, **calibrationVoiceSamplePath**, musicVolume (0–100), noiseReduction, voiceEnhancementEnabled, ducking, fadeInSeconds, fadeOutSeconds, normalizationEnabled, exportFormat, createdDate, modifiedDate. Enums (`NoiseLevel`/`DuckingStrength`/`ExportFormat`) stored as int index in Hive; serialized as readable strings in JSON export.

**Hive migration note:** `description` (field 13) and `calibrationVoiceSamplePath` (field 14) were appended — backward-compatible (old records read null), no migration script.

**Seed:** on first launch, 6 profiles (Corporate, Podcast, Soft Piano, Meditation, Training, Marketing).

---

## 5. Screens

| Screen | Role |
|---|---|
| **Home** | file selector, profile dropdown, Preview, Apply, recent files, batch entry (app-bar icon) |
| **Processing** | live % + stage checklist; Cancel (kills native session); success card (Open file) / failure card |
| **Batch** | add ≤50 files, one profile, Apply-all; per-file + overall progress; results summary |
| **Dataset Batch** | pick a root folder, add one+ filename suffixes (chips), one profile; recursively process all matches (no cap), output saved beside each source; live counts, cancel, completion summary, retry-failed |
| **Profiles** | list + Edit/Calibrate, Duplicate, Export, Delete (confirm); Import (app bar) |
| **Profile Wizard** | 4 steps: Info → Music → Calibration Sample → Calibrate (controls + live Preview + estimated output); draft auto-save |
| **History** | runs with status; tap to reopen output; clear-all |
| **Settings** | export folder/format, theme (live), auto-open, logging, clear cache, reset app |

Navigation: 4-tab bottom bar (Home/Profiles/History/Settings); Processing, Batch, Dataset Batch, Wizard are pushed routes (Batch + Dataset Batch via Home app-bar icons).

---

## 6. Development history (chronological)

### Design phase
- Produced full **SRS + architecture + 10-phase roadmap** (`SRS_AND_ARCHITECTURE.md`).
- **Decisions:** mobile-only (Android+iOS); output **mirrors source extension** (profile format picks codec within the container); **GPL** FFmpeg build; **single-invocation** pipeline; **−16 LUFS** target.

### Implementation phases (all device-verified on motorola edge 50 pro, API 36)
- **P0 Foundations** — deps, `core/` (Failure/Result/theme/logger), Hive bootstrap, go_router shell, 6 placeholder screens.
- **P1 Domain + Data** — entities, enums, repo interfaces, Hive models + adapters, mappers, repo impls, 6 seeded profiles.
- **P2 Profiles UX** — Profiles list (CRUD + duplicate), Profile editor (later replaced by wizard), persisted Settings, theme wired to settings.
- **P3 Audio engine** — `AudioProcessorPort`, `FilterGraphBuilder` (9-step graph), `StageTimeline`, `FfmpegAudioProcessor`. **Render confirmed on device** (WAV, MP3 320k, voice-only).
- **P4/P5 Apply flow** — `FileSystemService` (mirror-source naming, app-folder fallback), `ApplyProfileUseCase` (validate→resolve→render→history), Home + Processing screens. End-to-end verified on device.
- **P6 Preview** — 15 s trim render + just_audio playback.
- **P8 History + maintenance** — History screen (open exported file), Clear cache, Reset app (clear + reseed), auto-open.
- **P9 Hardening** — real Cancel button (kills native session); **perf: 3 min audio in 12.7 s ≈ 14.2× realtime** (→ 60 min ≈ 4.2 min), no crash.
- **P7 iOS** — deferred (no device; code is port-ready).

### Feature: Batch processing
`ProcessBatchUseCase` (sequential, reuses `ApplyProfileUseCase` per file, cap 50, failures don't abort), Batch screen, Home entry. **Device-verified** (3 files → 3 `_EchoBug` outputs).

### Feature: Dataset Batch processing (2026-06-22)
Processes an entire folder tree of audio files in one run — a **separate, additive** capability that leaves the manual Batch flow untouched. Built strictly by composition: **zero changes** to `ApplyProfileUseCase`, `ProcessBatchUseCase`, `BatchProgress`, `AudioFileRef`, or `BatchScreen`.
- **Flow:** pick a dataset root folder → add one or more filename suffixes (`_eng`, `_hin`, `_san`, entered via a text field + Add button, shown as removable chips) → pick a profile → Start. Every file under the tree whose name ends with `<suffix>.m4a` for **any** added suffix is processed; output written **beside its source** as `<name>_EchoBug.m4a` (existing `_uniquify` handles `_1/_2…` collisions).
- **Key design — `SameFolderFileSystem` decorator:** the single-file engine resolves output into the user's default export folder; this `FileSystemPort` decorator forces `preferredDir = dirname(source.path)` and delegates everything else, so a dataset-specific `ApplyProfileUseCase` (wired in DI) reuses validation + the FFmpeg engine + history recording verbatim while routing output next to each source. No audio/profile logic duplicated.
- **Components (all new):** `services/dataset/` → `DatasetFileScanner` (lazy recursive `Directory.list`, case-insensitive ext / case-sensitive suffix, any-of-N match), `DatasetBatchCancellationToken`, `SameFolderFileSystem`; domain → `ProcessDatasetUseCase` + entities `DatasetBatchConfig`/`DatasetAudioFile`/`DatasetBatchProgress`/`DatasetFileFailure`; presentation → `dataset_batch/` screen + kept-alive controller/state.
- **Scale & safety:** no file-count cap (calls `ApplyProfileUseCase` directly, bypassing the 50 limit); sequential to avoid native-render thrash; per-file failure isolation with captured error/stack; cooperative cancellation checked **between** files (in-flight file always finishes → no corrupt output); missing-at-process-time files counted as *skipped*; completion summary (total/processed/success/fail/skip + duration) with **View failed** and **Retry failed**.
- **Modifications to existing code — additive only:** 3 providers in `usecase_providers.dart`, 1 route in `app_router.dart`, 1 app-bar icon in `home_screen.dart`.
- **Status: host-tested only, NOT yet device-verified.** 22 host tests added (scanner, decorator, use-case orchestration incl. failure/cancel/retry/skip/empty); `flutter analyze` clean; full suite 47 green. No on-device dataset run yet (recommend verifying Android scoped-storage folder write on a real device before release).
- **Deferred:** `DatasetJob` Hive persistence (resume/audit) skipped to avoid a schema/registrar change — inputs persist in-session via the kept-alive controller; `.mp3/.wav/.aac` matching is wired via a configurable extension set (phase 1 = `m4a`).

### Feature: Profile Calibration & Preset Creator
Design in `PROFILE_CALIBRATION_DESIGN.md`. **Decisions:** wizard replaces flat editor; keep enums; export/import via `share_plus` (`.echobugprofile` JSON); preview 15 s; waveform deferred.
- Entity +`description` +`calibrationVoiceSamplePath`; Hive fields 13/14; JSON export/import.
- `profile_wizard/` (4-step) + `ProfileWizardController` (autoDispose family, **debounced draft auto-save** to `profile_draft` box for new profiles) + `CalibrationPreviewController` (reuses `GeneratePreviewUseCase`, **cancel-prior render**).
- `DraftRepository`, `ProfileTransferService`, Export/Import use cases.
- Flat editor (`profile_editor_screen.dart`) **deleted**.
- **Device-verified**: create → 2 live previews (with a tweak between) → save → persisted with calibration fields.

---

## 7. Notable engineering decisions & gotchas

- **FFmpeg Kit retirement:** the original `ffmpeg_kit_flutter` was retired early 2025; we use the maintained `ffmpeg_kit_flutter_new`. Its default build is **full-GPL** → all codecs (libmp3lame, AAC, FLAC, libvorbis, PCM) present; no variant config needed.
- **Hive → Hive CE:** original `hive`/`hive_generator` won't resolve on this SDK (analyzer/`_macros` removal). `hive_ce` is the drop-in.
- **Output container vs profile format:** output extension mirrors the *source*; the encoder is chosen from that container (`FilterGraphBuilder._encoderArgsForExtension`). The profile's export-format field is advisory when source/profile differ.
- **Path-with-space gotcha:** project path contains a space (`.../background /background_siq`). The **first** NDK/CMake configure can fail transiently; run `flutter build apk --debug` once to prime the cmake cache, then builds/tests work. (Renaming the folder to remove the space would eliminate this.)
- **`riverpod_lint` dropped** — pinned an incompatible analyzer; not needed at runtime.
- **Batch is sequential** — deliberate on mobile (concurrent native renders would thrash CPU/OOM). Concurrency, if ever wanted, is a one-line change in `ProcessBatchUseCase`.

---

## 8. Testing

**Host (47 tests, `flutter test`):** filter-graph builder (8), mappers (2), profile repo CRUD (5), apply orchestration (3), batch orchestration (3), maintenance reset (1), profile JSON round-trip (2), widget smoke (1), **dataset scanner (14)**, **same-folder file-system decorator (2)**, **dataset use-case orchestration (7: summary, failure-isolation, skip, cancel, retry, missing-profile, empty)**.

**On-device integration (`flutter test integration_test/<file> -d <device>`):**
- `render_test` — full pipeline → WAV, MP3 320k, voice-only
- `apply_flow_test` — real `meeting_EchoBug.wav` + history
- `m4a_test` — m4a in & out (AAC)
- `ui_walkthrough_test` — all 6 screens
- `perf_cancel_test` — long-file perf + cancellation
- `batch_test` — 3 files → 3 outputs
- `calibration_walkthrough_test` — wizard create → preview ×2 → save

All green.

---

## 9. Build & run

```bash
flutter pub get
dart run build_runner build          # regenerate freezed/json/hive after model changes
flutter analyze                      # must be clean
flutter test                         # host tests
flutter test integration_test/<f> -d <deviceId>   # on-device tests

# APKs (release; debug-signed — replace keystore before store upload)
flutter build apk --release                 # universal (~221 MB, all ABIs)
flutter build apk --release --split-per-abi # per-ABI (recommended for sharing)
#   app-arm64-v8a-release.apk   ~61 MB  → most modern phones (e.g. motorola edge 50 pro)
#   app-armeabi-v7a-release.apk ~95 MB  → older 32-bit phones (e.g. Samsung SM T580)
#   app-x86_64-release.apk      ~69 MB  → emulators
# Output: build/app/outputs/flutter-apk/
```

APKs are large because the full-GPL FFmpeg native libraries are bundled (offline requirement). The per-ABI splits are the right artifact to share.

---

## 10. Remaining / future

- **iOS bring-up** (CocoaPods + mic/file permissions) — code is port-ready.
- **Waveform preview** in the calibration sample step (FFmpeg peak extraction + CustomPainter) — deferred.
- **Real release signing** before any store distribution.
- **FLAC/OGG** output: codecs are bundled (full-GPL) but not yet individually device-run.
- Optional: batch concurrency on high-end devices; output-folder UX on Android 13+ scoped storage.
- **Dataset Batch: device verification** — confirm recursive folder write-back works under Android 13+ scoped storage on a real device (host-tested only so far); then consider `DatasetJob` Hive persistence (resume/audit) and enabling `.mp3/.wav/.aac` matching (extension set already configurable).
