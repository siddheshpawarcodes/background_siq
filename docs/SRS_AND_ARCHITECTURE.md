# Window Background Music (WBM) — SRS & Architecture Design

**Document status:** DRAFT FOR REVIEW — no implementation code is to be written until this is approved.
**Project codename:** `background_siq` (Flutter package name)
**Target platforms:** **Mobile only — Android + iOS.** (Desktop Windows/macOS explicitly out of scope. Architecture stays clean enough to add desktop later if ever needed, but no desktop work is planned or built.)
**Last updated:** 2026-06-15

---

## 0. How to read this document

This is the design-first deliverable. It covers all 16 required deliverables:

| # | Deliverable | Section |
|---|-------------|---------|
| 1 | Complete folder structure | §6 |
| 2 | Architecture diagram | §5 |
| 3 | Database schema | §8 |
| 4 | Hive models | §8.2 |
| 5 | Riverpod providers | §9 |
| 6 | Domain entities | §7.1 |
| 7 | Repositories | §7.3 |
| 8 | Use cases | §7.2 |
| 9 | FFmpeg service | §10 |
| 10 | UI screens | §11 |
| 11 | Navigation flow | §12 |
| 12 | Error handling strategy | §13 |
| 13 | State management strategy | §9 |
| 14 | Background processing design | §14 |
| 15 | Future scalability plan | §15 |
| 16 | Complete implementation roadmap | §16 |

---

## 1. Software Requirements Specification (SRS)

### 1.1 Purpose
WBM is a 100% offline desktop/mobile Flutter app that mixes a spoken-voice recording with a
background-music track and produces a broadcast-quality output file. All processing is local;
no network, cloud, API key, account, or subscription is ever required or used.

### 1.2 Scope
The app ingests a single voice recording, applies a deterministic 9-step audio pipeline driven
by a reusable **Background Music Profile**, and exports a processed file named `<source>_WBM.<ext>`.
Profiles, settings, recent files, and processing history persist locally via Hive.

### 1.3 Definitions
- **Profile** — a saved bundle of processing parameters + a chosen music file.
- **Ducking** — automatic reduction of music level while speech is present (side-chain compression).
- **LUFS** — Loudness Units Full Scale (EBU R128 / ITU-R BS.1770 loudness measure).
- **Isolate** — Dart's unit of concurrency; used to keep the UI thread responsive.

### 1.4 Functional requirements
- **FR-1** Pick a voice file via the system file picker (mp3, wav, m4a, aac, flac, ogg).
- **FR-2** Select a saved profile from a dropdown.
- **FR-3** Apply → run the full pipeline with zero further interaction.
- **FR-4** Show stepwise progress with percentage.
- **FR-5** Save output beside the source when permitted; else to the configured output folder.
- **FR-6** Append `_WBM` suffix; preserve the container extension (or the profile's export format — see §3.1).
- **FR-7** CRUD + duplicate profiles.
- **FR-8** 15-second local preview using full profile settings.
- **FR-9** Persist profiles, preferences, recent files, settings, history.
- **FR-10** History screen with reopen-output capability.
- **FR-11** Settings: default folder, default format, theme, auto-open, logging, clear cache, reset.
- **FR-12** Architecture must allow future batch processing (queue of N files).

### 1.5 Non-functional requirements
- **NFR-1 Offline:** no runtime network calls. (Enforced — see §13.5.)
- **NFR-2 Performance:** handle 30 s → 60 min files without crash; UI stays at 60 fps; processing in a background isolate.
- **NFR-3 Quality:** output normalized to a consistent loudness target with no clipping (true-peak ≤ −1.5 dBTP).
- **NFR-4 Cross-platform:** single codebase for **Android + iOS**; platform differences isolated behind interfaces.
- **NFR-5 Reliability:** every failure mode in §13 produces a clear, actionable, user-facing message; no silent failures.
- **NFR-6 Determinism:** same input + same profile ⇒ byte-comparable pipeline parameters (loudnorm two-pass aside).

### 1.6 Assumptions & constraints
- Single-file processing in v1; batch is architecturally supported but UI-deferred.
- Voice file is primarily speech; the EQ/compression presets assume spoken word.
- Output container is derived from the **profile export format** (§3.1) — this resolves the spec's
  "keep extension" vs. "user selects format" tension; see the open question in §17.

---

## 2. Primary user flow

```
┌─────────┐   ┌──────────────┐   ┌────────────────┐   ┌────────┐   ┌────────────┐   ┌──────────┐
│  Open   │──▶│ Pick voice   │──▶│ Pick profile   │──▶│ Apply  │──▶│ Processing │──▶│ Output   │
│  app    │   │ file         │   │ (dropdown)     │   │ button │   │ progress   │   │ _WBM file│
└─────────┘   └──────────────┘   └────────────────┘   └────────┘   └────────────┘   └──────────┘
                                         │
                                         └── optional ── Preview (first 15 s) ──▶ in-app playback
```

No interaction is required between **Apply** and **Output**.

---

## 3. Audio processing pipeline (functional spec)

Execution order is fixed:

| Step | Stage | FFmpeg mechanism | Profile-driven |
|------|-------|------------------|----------------|
| 1 | Import voice | demux/decode | — |
| 2 | Noise reduction | `afftdn` (+ optional `arnndn`) | Off/Mild/Medium/Aggressive |
| 3 | Voice enhancement | `highpass`,`equalizer`,`acompressor` | on/off |
| 4 | Music mix | `volume` + `amix` | musicVolume 0–100% |
| 5 | Auto ducking | `sidechaincompress` | Off/Light/Medium/Strong |
| 6 | Fade in | `afade=t=in` | 0–10 s |
| 7 | Fade out | `afade=t=out` | 0–10 s |
| 8 | Loudness normalize | `loudnorm` (EBU R128) | on/off |
| 9 | Export | encoder selection | MP3 320 / AAC 256 / WAV |

Exact filter graphs are in §10.

### 3.1 Output format & naming resolution — **DECIDED: mirror source extension**
- File is named `<basename>_WBM.<source-ext>`. The output **container/extension always mirrors the source**
  (`meeting.mp3 → meeting_WBM.mp3`, `training.wav → training_WBM.wav`). ✅ matches spec examples literally.
- The profile's **export format** then selects the **codec + quality tier within that container**:
  - source container natively matches a tier → use it (`.mp3`→libmp3lame 320, `.m4a/.aac`→AAC 256, `.wav`→pcm_s24le).
  - source container does not match the profile's format (e.g. `.mp3` source + WAV-lossless profile) →
    **container wins**, we encode the best codec that fits the source container at the highest tier, and log
    a one-line note ("export format adjusted to fit source container"). No silent format surprise.
- Consequence noted: under mirror-source, the export-format setting is advisory when source/profile containers
  diverge. Acceptable per decision; revisit only if users report confusion.

---

## 4. Technology stack (proposed)

| Concern | Choice | Rationale |
|---------|--------|-----------|
| Framework | Flutter (Dart ≥ 3.11) | Cross-platform single codebase |
| State mgmt | **Riverpod** (`flutter_riverpod` + `riverpod_annotation`/codegen) | Compile-safe DI, testable, no `BuildContext` coupling |
| Local DB | **Hive CE** (`hive_ce`, `hive_ce_flutter`, `hive_ce_generator`) | Maintained drop-in for Hive (which is abandoned & incompatible with the current analyzer/SDK); same API, offline, no native deps |
| Audio engine | **FFmpeg** via a maintained mobile fork, behind an abstraction (§10.1) | Required; in-process on Android (JNI) + iOS |
| File picking | `file_picker` | System picker on all targets |
| Path/permissions | `path_provider`, `permission_handler`, `path` | Folder resolution, runtime perms |
| Playback (preview) | `just_audio` | Cross-platform local playback |
| Routing | `go_router` | Declarative, deep-link ready |
| Logging | `logger` + file sink | Settings-toggleable logging |
| Codegen | `freezed`, `json_serializable`, `riverpod_generator`, `hive_generator`, `build_runner` | Immutable models, less boilerplate |

> **Risk R-1 (critical):** the original `ffmpeg_kit_flutter` (Arthenica) was **retired in early 2025** and its
> prebuilt binaries were removed from public registries. The design therefore does **not** hard-depend on it.
> See §10.1 for the backend-abstraction mitigation and the platform-specific binary plan.

---

## 5. Architecture diagram

Clean Architecture, dependencies point inward (Presentation → Domain ← Data; Services injected via Domain ports).

```
┌──────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION                                    │
│  Screens (Home, Profiles, ProfileEditor, Processing, History, Settings)    │
│  Riverpod Notifiers/Providers · go_router · Widgets (no business logic)    │
└───────────────────────────────┬────────────────────────────────────────────┘
                                 │ calls use cases (abstractions only)
┌───────────────────────────────▼────────────────────────────────────────────┐
│                               DOMAIN                                         │
│  Entities (Profile, ProcessingJob, HistoryEntry, AppSettings, AudioFileRef) │
│  Use cases (ApplyProfile, GeneratePreview, CRUD profiles, …)                │
│  Repository INTERFACES · Service PORTS (AudioProcessorPort, FileSystemPort)  │
└───────────────┬──────────────────────────────────────┬─────────────────────┘
                │ implemented by                        │ implemented by
┌───────────────▼───────────────┐      ┌────────────────▼─────────────────────┐
│            DATA                │      │            SERVICES                   │
│  Repository impls              │      │  FFmpegAudioProcessor (port impl)     │
│  Hive datasources + adapters   │      │  FilterGraphBuilder                   │
│  DTO ⇄ Entity mappers          │      │  IsolateProcessRunner                 │
│  (Profiles, Settings, History, │      │  FileSystemService, PermissionService │
│   RecentFiles boxes)           │      │  AudioProbeService (ffprobe/metadata) │
└────────────────────────────────┘      └───────────────────────────────────────┘
                │                                        │
                └──────────────► CORE ◄──────────────────┘
        (Failure types, Result/Either, constants, theme, DI bootstrap, logger)
```

---

## 6. Folder structure

```
lib/
├── main.dart                          # bootstrap: Hive init, ProviderScope, router
├── core/
│   ├── constants/                     # supported formats, suffix "_WBM", defaults
│   ├── errors/                        # Failure hierarchy, AppException
│   ├── result/                        # Result<T>/Either alias (fpdart or custom)
│   ├── theme/                         # ThemeData light/dark, design tokens
│   ├── di/                            # provider overrides, bootstrap
│   ├── logging/                       # logger config + file sink
│   └── utils/                         # path helpers, duration fmt, validators
├── domain/
│   ├── entities/
│   │   ├── background_profile.dart
│   │   ├── processing_job.dart
│   │   ├── history_entry.dart
│   │   ├── app_settings.dart
│   │   ├── audio_file_ref.dart
│   │   └── enums.dart                 # NoiseLevel, DuckingStrength, ExportFormat, JobStage
│   ├── repositories/                  # abstract interfaces
│   │   ├── profile_repository.dart
│   │   ├── settings_repository.dart
│   │   ├── history_repository.dart
│   │   └── recent_files_repository.dart
│   ├── ports/                         # service interfaces (hexagonal)
│   │   ├── audio_processor_port.dart
│   │   ├── file_system_port.dart
│   │   └── permission_port.dart
│   └── usecases/
│       ├── apply_profile_usecase.dart
│       ├── generate_preview_usecase.dart
│       ├── process_batch_usecase.dart        # future-ready, queue of jobs
│       ├── pick_audio_file_usecase.dart
│       ├── crud_profile_usecases.dart
│       ├── manage_settings_usecase.dart
│       └── history_usecases.dart
├── data/
│   ├── models/                        # Hive DTOs + freezed/json
│   │   ├── profile_model.dart (+ .g.dart adapter)
│   │   ├── settings_model.dart
│   │   ├── history_model.dart
│   │   └── recent_file_model.dart
│   ├── datasources/                   # HiveBox wrappers
│   ├── mappers/                       # model ⇄ entity
│   └── repositories/                  # *RepositoryImpl
├── services/
│   ├── audio/
│   │   ├── ffmpeg_audio_processor.dart        # AudioProcessorPort impl
│   │   ├── backends/                          # mobile fork vs desktop binary
│   │   │   ├── ffmpeg_kit_backend.dart
│   │   │   └── ffmpeg_process_backend.dart
│   │   ├── filter_graph_builder.dart          # profile → filter_complex string
│   │   ├── audio_probe_service.dart           # duration, channels, codec
│   │   └── isolate_process_runner.dart        # runs ffmpeg off the UI thread
│   ├── filesystem/
│   └── platform/
├── presentation/
│   ├── app.dart                       # MaterialApp.router
│   ├── router/app_router.dart
│   ├── features/
│   │   ├── home/                      # screen + notifier + widgets
│   │   ├── profiles/
│   │   ├── profile_editor/
│   │   ├── processing/
│   │   ├── history/
│   │   └── settings/
│   └── shared/                        # reusable widgets (sliders, dropdowns, file chip)
└── features/                          # (reserved per spec; cross-feature shared flows)
```

> Note: the spec lists both `features/` and `presentation/`. We place feature UI under
> `presentation/features/` (standard Clean+Riverpod layout) and keep top-level `features/` reserved
> for cross-cutting feature orchestration if needed. **(Flagged — §17, Q2.)**

---

## 7. Domain layer

### 7.1 Entities (immutable, `freezed`)

```dart
// enums.dart
enum NoiseLevel { off, mild, medium, aggressive }
enum DuckingStrength { off, light, medium, strong }
enum ExportFormat { mp3, aac, wav }          // mp3 320k, aac 256k, wav lossless
enum JobStage { preparing, denoising, enhancing, mixing, ducking, fading, normalizing, exporting, completed, failed }

// background_profile.dart  (domain entity — pure, no Hive annotations)
class BackgroundProfile {
  final String id;                 // uuid
  final String name;
  final String? musicFilePath;
  final int musicVolume;           // 0..100, default 20
  final NoiseLevel noiseReduction;
  final bool voiceEnhancementEnabled;
  final DuckingStrength ducking;
  final double fadeInSeconds;      // 0..10
  final double fadeOutSeconds;     // 0..10
  final bool normalizationEnabled;
  final ExportFormat exportFormat;
  final DateTime createdDate;
  final DateTime modifiedDate;
}

// audio_file_ref.dart
class AudioFileRef { final String path; final String name; final String ext; final int? sizeBytes; final Duration? duration; }

// processing_job.dart  (transient, drives the progress UI)
class ProcessingJob {
  final String id; final AudioFileRef source; final BackgroundProfile profile;
  final JobStage stage; final double progress; // 0..1
  final String? outputPath; final Object? error;
}

// history_entry.dart
class HistoryEntry {
  final String id; final String sourcePath; final String outputPath;
  final DateTime date; final String profileName; final Duration processingTime;
  final JobStatus status; // success | failed
}

// app_settings.dart
class AppSettings {
  final String? defaultExportFolder; final ExportFormat defaultExportFormat;
  final ThemeMode themeMode; final bool autoOpenOutputFolder;
  final bool loggingEnabled;
}
```

### 7.2 Use cases (single responsibility, return `Result<T>`)
- `ApplyProfileUseCase(source, profile) → Stream<ProcessingJob>` — emits stage/progress updates.
- `GeneratePreviewUseCase(source, profile) → Result<String>` — 15 s rendered clip path.
- `PickAudioFileUseCase() → Result<AudioFileRef>`.
- `Create/Update/Delete/DuplicateProfileUseCase`.
- `LoadProfilesUseCase`, `GetSettingsUseCase`, `UpdateSettingsUseCase`.
- `AddHistoryEntryUseCase`, `LoadHistoryUseCase`, `OpenOutputUseCase`.
- `ProcessBatchUseCase(List<source>, profile) → Stream<BatchProgress>` — **built now, UI later** (§15).

### 7.3 Repository interfaces
- `ProfileRepository`: `watchAll()`, `getById`, `save`, `delete`, `duplicate`.
- `SettingsRepository`: `get()`, `update()`.
- `HistoryRepository`: `watchAll()`, `add`, `clear`.
- `RecentFilesRepository`: `recent()`, `push`, `clear`.

### 7.4 Service ports
- `AudioProcessorPort`: `process(spec) → Stream<ProcessingProgress>`, `preview(spec) → Future<String>`, `probe(path) → AudioMeta`, `cancel(jobId)`.
- `FileSystemPort`: output-path resolution, write permission probe, open-in-OS.
- `PermissionPort`: request/check storage permissions per platform.

---

## 8. Storage / database schema (Hive)

### 8.1 Boxes
| Box | Key | Value type | Purpose |
|-----|-----|-----------|---------|
| `profiles` | profile.id (String) | `ProfileModel` | Background music profiles |
| `settings` | `'app'` (singleton) | `SettingsModel` | App preferences |
| `history` | entry.id | `HistoryModel` | Processing history |
| `recent_files` | path hash | `RecentFileModel` | Recently picked sources |

### 8.2 Hive models (DTOs, `@HiveType`)

```dart
@HiveType(typeId: 0)
class ProfileModel {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? musicFilePath;
  @HiveField(3) int musicVolume;             // 0..100
  @HiveField(4) int noiseReductionLevel;     // enum index
  @HiveField(5) bool voiceEnhancementEnabled;
  @HiveField(6) int duckingStrength;         // enum index
  @HiveField(7) double fadeInSeconds;
  @HiveField(8) double fadeOutSeconds;
  @HiveField(9) bool normalizationEnabled;
  @HiveField(10) int exportFormat;           // enum index
  @HiveField(11) DateTime createdDate;
  @HiveField(12) DateTime modifiedDate;
}

@HiveType(typeId: 1) class SettingsModel { /* defaultExportFolder, defaultExportFormat,
  themeMode(int), autoOpenOutputFolder(bool), loggingEnabled(bool) */ }

@HiveType(typeId: 2) class HistoryModel { /* id, sourcePath, outputPath, date, profileName,
  processingMillis, status(int) */ }

@HiveType(typeId: 3) class RecentFileModel { /* path, name, lastUsed */ }
```

Enums stored as `int` indices via dedicated adapters or index fields to keep the schema migration-safe.
**Seed data:** on first launch, seed the six default profiles (Corporate, Podcast, Soft Piano, Meditation,
Training, Marketing) with sensible parameter presets.

---

## 9. State management strategy (Riverpod)

- **DI/bootstrap:** Hive boxes, repositories, services exposed as providers; overridable in tests.
- **Profiles:** `profilesProvider` (StreamProvider over `watchAll()`); editor uses an
  `AutoDisposeNotifier` holding a draft `BackgroundProfile`.
- **Home:** `homeControllerProvider` (Notifier) holds selected file + selected profile id.
- **Processing:** `processingControllerProvider` exposes `AsyncValue<ProcessingJob>`; subscribes to the
  use case's `Stream<ProcessingJob>` and surfaces stage + percentage.
- **Settings/Theme:** `settingsProvider` (Notifier); `themeModeProvider` derived for `MaterialApp`.
- **History:** `historyProvider` (StreamProvider).
- **Rule:** widgets only read providers and call notifier methods. **No business logic in widgets**;
  all orchestration lives in use cases invoked by notifiers.

```
Widget ──read──▶ Notifier ──calls──▶ UseCase ──▶ Repository/Port
  ▲                                                   │
  └──────────── AsyncValue / Stream ──────────────────┘
```

---

## 10. FFmpeg service & strategy

### 10.1 Backend abstraction (de-risking the retired plugin — R-1)
`AudioProcessorPort` is the only thing the domain knows. A single mobile backend implements it:

- **Android + iOS:** a maintained community fork of FFmpeg Kit (e.g. `ffmpeg_kit_flutter_new`) that
  re-hosts the **`full-gpl`** binaries — bundling `libmp3lame` (MP3 320), `libvorbis` (OGG), AAC, FLAC, etc.
  Runs **in-process** (JNI on Android, native lib on iOS) on its own native thread.

Keeping `AudioProcessorPort` as the seam means a desktop backend (bundled ffmpeg executable via `Process`)
could be added later without touching domain/UI — but it is **not built** for this mobile-only release.
`FilterGraphBuilder` produces a single `filter_complex` string the backend executes verbatim.

> **Licensing — DECIDED: GPL build.** We ship `full-gpl` so MP3/OGG encode is guaranteed on both platforms.
> The app's distribution terms must therefore be GPL-compatible. (Resolved — §17, Q3.)

### 10.2 Filter graph builder (profile → command)

**Per-stage filters:**

| Stage | Filter (representative) |
|-------|-------------------------|
| Denoise — Mild | `afftdn=nr=10:nf=-25` |
| Denoise — Medium | `afftdn=nr=20:nf=-30` |
| Denoise — Aggressive | `highpass=f=80,afftdn=nr=30:nf=-35` (optional `arnndn=m=rnnoise.model` if model bundled) |
| Voice EQ | `highpass=f=80,equalizer=f=200:t=q:w=1:g=-2,equalizer=f=3000:t=q:w=1.5:g=4` |
| Compression | `acompressor=threshold=-18dB:ratio=3:attack=5:release=60:makeup=2` |
| Music volume | `volume=<musicVolume/100>` |
| Ducking — Light | `sidechaincompress=threshold=0.05:ratio=4:attack=20:release=300` |
| Ducking — Medium | `sidechaincompress=threshold=0.03:ratio=8:attack=15:release=250` |
| Ducking — Strong | `sidechaincompress=threshold=0.02:ratio=20:attack=10:release=200` |
| Fade in | `afade=t=in:st=0:d=<fadeIn>` |
| Fade out | `afade=t=out:st=<dur-fadeOut>:d=<fadeOut>` |
| Normalize | `loudnorm=I=-16:TP=-1.5:LRA=11` (two-pass; see §10.3) |

**Assembled graph (ducking ON):**
```
ffmpeg -i voice.ext -stream_loop -1 -i music.ext -filter_complex "
  [0:a]highpass=f=80,afftdn=nr=20:nf=-30,
       equalizer=f=200:t=q:w=1:g=-2,equalizer=f=3000:t=q:w=1.5:g=4,
       acompressor=threshold=-18dB:ratio=3:attack=5:release=60:makeup=2,
       asplit=2[v_mix][v_sc];
  [1:a]volume=0.20[mus];
  [mus][v_sc]sidechaincompress=threshold=0.03:ratio=8:attack=15:release=250[ducked];
  [ducked][v_mix]amix=inputs=2:duration=first:dropout_transition=0[mixed];
  [mixed]afade=t=in:st=0:d=3,afade=t=out:st=<dur-3>:d=3,
         loudnorm=I=-16:TP=-1.5:LRA=11[out]
" -map "[out]" <encoder-args> output_WBM.<ext>
```
- `-stream_loop -1` loops the music; `amix=duration=first` trims to the voice length.
- `asplit` feeds the voice both to the mix and to the side-chain key.
- Ducking OFF ⇒ drop `sidechaincompress`, mix `[mus]` directly.
- Music absent (profile has no music) ⇒ voice-only chain (denoise→enhance→fade→normalize).

**Encoder args by export format:**
| Format | Args |
|--------|------|
| MP3 320 | `-c:a libmp3lame -b:a 320k` |
| AAC 256 | `-c:a aac -b:a 256k -movflags +faststart` (`.m4a`) |
| WAV | `-c:a pcm_s24le` (lossless) |

### 10.3 Loudness normalization (quality) — **DECIDED: −16 LUFS**
Use **two-pass `loudnorm`** for accuracy on the final render: pass 1 measures (`print_format=json`),
pass 2 applies measured values. Targets: **−16 LUFS integrated, −1.5 dBTP true peak, LRA 11** (podcast/voice
standard; configurable later). Single-pass is acceptable for the 15 s preview to keep it fast.

### 10.4 Progress reporting — **DECIDED: single ffmpeg invocation**
The mobile fork exposes a **statistics callback** (`time`/`size`); divide reported `time` by total duration
(from `probe`) → 0..1. The whole 9-step pipeline runs as **one ffmpeg session** (one `filter_complex`), so
stage labels are derived from a weighted timeline (prepare 5% → measure-pass 10% → render 80% →
finalize 5%) rather than separate processes — faster, no intermediate temp files. (Resolved — §17, Q4.)

### 10.5 Preview
`-t 15` (or `atrim`) on inputs + identical filter graph + single-pass loudnorm → temp file in cache dir →
played via `just_audio`. Deleted on cache-clear.

---

## 11. UI screens

1. **Home / Main** — file selector chip, profile dropdown, Preview button, **Apply** (primary CTA),
   recent files list. Disabled Apply until file + profile chosen.
2. **Processing** — animated stage list with checkmarks, linear % progress, cancel button, result card
   (open file / open folder / share).
3. **Profiles** — list with add / edit / duplicate / delete (swipe or menu), default badge.
4. **Profile Editor** — name, music file picker, volume slider (0–100, default 20), noise reduction
   segmented control, voice-enhancement switch, ducking segmented control, fade-in/out sliders (0–10 s),
   export-format selector, save/cancel. Inline mini-preview button.
5. **History** — reverse-chronological entries (source→output, date, profile, duration, status); tap to
   reopen output; clear-all.
6. **Settings** — default export folder picker, default export format, theme (light/dark/system),
   auto-open output folder, enable logging, clear cache, reset app (with confirm dialog).

Design language: Material 3, responsive layout (mobile single-column / desktop two-pane where useful),
light+dark themes from `core/theme`.

---

## 12. Navigation flow (go_router)

```
/                     Home
/processing/:jobId    Processing (pushed on Apply)
/profiles             Profiles list
/profiles/edit/:id?   Profile editor (id absent = create)
/history              History
/settings             Settings
```
Top-level destinations (Home, Profiles, History, Settings) via NavigationRail (desktop) /
NavigationBar (mobile). Processing & editor are pushed routes.

---

## 13. Error handling strategy

### 13.1 Failure model
A sealed `Failure` hierarchy returned via `Result<T>` (no throwing across layers):
`FileNotFound`, `CorruptFile`, `UnsupportedFormat`, `InsufficientStorage`, `PermissionDenied`,
`FfmpegFailure(stderr, code)`, `ProfileNotFound`, `ExportFailure`, `Cancelled`, `UnknownFailure`.

### 13.2 Mapping to user messages
Each `Failure` maps to a localized, plain-language message + optional remedy action
(e.g. PermissionDenied → "Grant storage access" button → opens settings).

### 13.3 Pre-flight validation (before invoking ffmpeg)
- File exists & readable; extension in supported set; `probe` succeeds (catches corrupt files early);
  free disk space ≥ estimated output size; output folder writable (fallback to app folder).

### 13.4 FFmpeg failures
Capture stderr, log it (if logging on), classify common patterns (missing codec, invalid data) into the
right `Failure`, never expose raw stderr to the user (available in logs only).

### 13.5 Offline enforcement
No HTTP client is added to the dependency set; CI lint rule forbids `dart:io HttpClient`/`http`/`dio`.
FFmpeg invoked with local paths only. (NFR-1.)

---

## 14. Background processing design

- The full ffmpeg run executes **off the UI thread**:
  - The FFmpeg fork runs natively on its **own background thread** (Android/iOS); progress + result
    marshaled back to Dart via its async callbacks — the Flutter UI isolate never blocks.
  - CPU-heavy Dart pre/post work (probe JSON parsing, two-pass loudnorm measurement parsing) runs in a
    Dart isolate via `Isolate.run`.
- Cancellation: `cancel(jobId)` cancels the ffmpeg session; partial output deleted.
- UI subscribes to a broadcast `Stream<ProcessingJob>`; back-pressure-safe (throttle progress to ~10 Hz).
- Temp/intermediate files live in the OS cache dir and are GC'd on completion and on Settings→Clear cache.

---

## 15. Future scalability plan

- **Batch mode:** `ProcessBatchUseCase` + a `JobQueue` are implemented now (sequential, 1 active job),
  emitting `BatchProgress`. UI is the only missing piece — add a multi-select on Home + a queue screen later.
- **Parallelism:** queue can later run N concurrent ffmpeg processes bounded by CPU count (desktop).
- **More effects:** pipeline is a list of composable `FilterStage` objects → new stages (de-reverb,
  de-esser, stereo widening) plug in without touching orchestration.
- **More formats / codecs:** export registry is data-driven; add entries + encoder args.
- **Cloud-optional sync** (still offline-first): profiles export/import as JSON for manual sharing.
- **i18n:** message catalog already centralized in §13.2 → wrap with `intl`.

---

## 16. Implementation roadmap (phased)

| Phase | Deliverable | Exit criteria |
|-------|-------------|---------------|
| **P0 Foundations** | pubspec deps, codegen setup, `core/` (Failure, Result, theme, logger, DI), Hive bootstrap, go_router shell | App builds & runs on Android + iOS with empty screens |
| **P1 Domain + Data** | Entities, enums, repository interfaces, Hive models+adapters, repo impls, seed default profiles | Profiles persist; unit tests on mappers/repos green |
| **P2 Profiles UX** | Profiles list + Profile editor + Settings + theme | Full CRUD/duplicate; settings persist |
| **P3 Audio engine** | `AudioProcessorPort`, FFmpeg-fork backend (Android first), `FilterGraphBuilder`, probe service, isolate runner, storage permissions | Voice-only + music-mix render produces valid `_WBM` file on Android |
| **P4 Pipeline complete** | Ducking, fades, two-pass loudnorm, all export formats, progress mapping | All 9 steps verified by listening + loudnorm measurement |
| **P5 Apply flow + Processing UI** | Home selection, Apply, stage/% UI, output save+naming, auto-open | End-to-end primary flow on Android |
| **P6 Preview** | 15 s render + in-app playback | Preview matches full-render character |
| **P7 iOS bring-up** | iOS FFmpeg fork pods, file/permission parity, save-to-Files | Same pipeline runs on iOS |
| **P8 History + polish** | History screen, error UX, clear cache/reset, logging sink | All §13 failures show friendly messages |
| **P9 Hardening** | 30 s→60 min perf tests, cancellation, edge cases, docs | NFR-2 met; no crashes on 60 min file |
| **P10 (later)** | Batch UI on top of existing `ProcessBatchUseCase` | Multi-file queue |

---

## 17. Decisions log & remaining questions

**Resolved (2026-06-15):**
- **Q1 — Output extension:** ✅ **Mirror source extension.** Profile export format selects codec/quality
  within the source container; container wins on conflict (§3.1).
- **Q3 — FFmpeg licensing:** ✅ **GPL (`full-gpl`) build** — MP3/OGG encode guaranteed; distribution must be GPL-compatible.
- **Q4 — Pipeline model:** ✅ **Single ffmpeg invocation** for the whole 9-step chain.
- **Q5 — Loudness target:** ✅ **−16 LUFS** integrated, −1.5 dBTP, LRA 11.
- **Q6 — Platforms:** ✅ **Mobile only — Android + iOS.** Windows/macOS out of scope.

**Still open (non-blocking — can proceed; default in parentheses):**
- **Q2 — Folder layout:** consolidate feature UI under `presentation/features/`, keep top-level `features/`
  reserved (default: yes), or strict literal two-dir match to the spec?

---

*End of design. Awaiting approval before Phase 0 implementation.*
```
