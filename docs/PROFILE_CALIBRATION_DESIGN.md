# Profile Calibration & Audio Preset Creator — Design (FOR REVIEW)

**Status:** DRAFT — no implementation until approved.
**Date:** 2026-06-15
**Scope:** Add a guided Profile Creation Wizard + dedicated Calibration screen with live preview, plus profile export/import — on top of the existing offline FFmpeg engine.

---

## 1. Analysis of the existing architecture (what we already have)

This feature is **~70% already built and device-verified**. The honest picture:

| Spec requirement | Current state | Work needed |
|---|---|---|
| Profile data model | `BackgroundProfile` entity + Hive `ProfileModel` (typeId 0) | **Add 2 fields**: `description`, `calibrationVoiceSamplePath` |
| Background music selection | `FilePickService.pickAudioPath()` + editor music picker | Reuse; add duration/size display |
| Audio processing settings (volume, noise, ducking, fades, normalize, format) | All present in entity + editor controls + `FilterGraphBuilder` | Reuse as-is |
| Live preview (first 15 s, all settings, mix, DSP, temp output, play) | `GeneratePreviewUseCase` (trim 15 s, full pipeline) + `just_audio` playback | **Reuse directly** — feed it the calibration sample + draft |
| Fast preview (trim, temp, delete) | Single-pass trim render to one temp path | Add cancel/debounce + delete-on-exit |
| Iterative calibration | Preview is repeatable | Reuse; add cancel-prior-preview |
| Save config only (no rendered audio) | Repo stores only the entity | Already correct |
| Hive storage | `hive_ce`, adapters, repo CRUD + duplicate | Backward-compatible field add |
| Create/Edit/Duplicate/Delete/Rename | Profiles screen + editor + repo | Reuse (rename = save) |
| **Export / Import profile** | — | **New** (JSON serialize + file pick/share) |
| Main app integration (file + profile → Apply) | Done & device-verified | No change |
| Background processing / no UI freeze | Native FFmpeg thread, 14.2× realtime, verified | No change |
| Clean Arch / Riverpod / DI / SOLID | In place | Extend same patterns |

**Conclusion:** the DSP, preview engine, storage, and production Apply flow already exist and pass on-device. This feature is mostly **UX (wizard + calibration screen)** + **2 model fields** + **export/import** + optional **waveform**.

---

## 2. Feature architecture

Same Clean Architecture layers; additions only:

```
presentation/features/profile_wizard/
  profile_wizard_screen.dart        # 4-step PageView host + progress
  steps/step_info.dart              # name + description
  steps/step_music.dart             # music pick + duration/size
  steps/step_calibration_sample.dart# voice sample pick + (optional) waveform
  steps/step_calibrate.dart         # all controls + Preview + Save
  profile_wizard_controller.dart    # AutoDisposeNotifier<WizardState> (draft)
  calibration_preview_controller.dart # AsyncValue preview path + play state
  widgets/waveform_view.dart        # optional CustomPainter
domain/usecases/
  export_profile_usecase.dart       # NEW
  import_profile_usecase.dart       # NEW
  draft_usecases.dart               # save/load/clear draft (auto-save)
services/audio/
  waveform_service.dart             # OPTIONAL: FFmpeg peak extraction
data/ (extend existing)
  ProfileModel +description +calibrationVoiceSamplePath; draft box
```

Everything else (engine, FilterGraphBuilder, GeneratePreviewUseCase, repos) is reused unchanged.

---

## 3. Data model

Extend the existing entity (the spec's `AudioProfile` == our `BackgroundProfile` + 2 fields; `createdAt/modifiedAt` already exist as `createdDate/modifiedDate`):

```dart
@freezed
abstract class BackgroundProfile with _$BackgroundProfile {
  const factory BackgroundProfile({
    required String id,
    required String name,
    String? description,                 // NEW
    String? musicFilePath,
    String? calibrationVoiceSamplePath,  // NEW (calibration-only; see §9)
    @Default(20) int musicVolume,
    @Default(NoiseLevel.medium) NoiseLevel noiseReduction,
    @Default(true) bool voiceEnhancementEnabled,
    @Default(DuckingStrength.medium) DuckingStrength ducking,
    @Default(0.0) double fadeInSeconds,
    @Default(0.0) double fadeOutSeconds,
    @Default(true) bool normalizationEnabled,
    @Default(ExportFormat.mp3) ExportFormat exportFormat,
    required DateTime createdDate,
    required DateTime modifiedDate,
  }) = _BackgroundProfile;

  factory BackgroundProfile.fromJson(Map<String,dynamic> j) => _$...; // NEW for export/import
}
```

**Hive migration:** add `@HiveField(13) String? description` and `@HiveField(14) String? calibrationVoiceSamplePath` to `ProfileModel`. Appending new field indices is **backward-compatible** — existing records simply read null. No data loss, no migration script.

**Enums vs strings:** the spec shows `String noiseReductionLevel`. We keep the existing **type-safe enums** (`NoiseLevel`/`DuckingStrength`/`ExportFormat`) — strictly better; the spec used strings illustratively. (Decision Q3.)

---

## 4. Navigation flow

```
Profiles screen
  ├─ FAB "New Profile" ──────────────▶ /profiles/wizard            (create)
  └─ row "Edit"/"Calibrate" ─────────▶ /profiles/wizard?id=<id>    (edit: loads saved settings)

/profiles/wizard  (4-step PageView)
  Step 1 Info ▸ Step 2 Music ▸ Step 3 Calibration Sample ▸ Step 4 Calibrate
                                                                  │
                                                       [Preview] (in-place)
                                                       [Save Profile] ─▶ back to Profiles
```

The guided wizard **replaces the current flat editor** for both create and edit (Decision Q1). Step 4 (Calibrate) is the heart and is also reachable directly via a "Calibrate" action on an existing profile. Export/Import live as actions on the Profiles screen + the row menu.

---

## 5. FFmpeg strategy

**No new filters.** Calibration reuses `FilterGraphBuilder` + `GeneratePreviewUseCase` exactly:

- Preview = `process` with `trim: 15s`, single FFmpeg invocation, single-pass `loudnorm` (fast).
- Input = the **calibration voice sample**; music = the draft's `musicFilePath`; all DSP from the draft profile.
- Output = one reused temp file (`echobug_preview.<sampleExt>`), played via `just_audio`.
- **Cancel/replace:** each Preview gets a job id; starting a new preview cancels the prior native session (`AudioProcessorPort.cancel`) so rapid iteration doesn't pile up renders.

Production Apply is unchanged and already uses every profile field.

---

## 6. Profile storage strategy

- **Profiles:** existing Hive `profiles` box (typeId 0, +2 fields).
- **Draft auto-save (UX req):** a tiny `draft` box keyed `'current'` storing the in-progress `ProfileModel`. Written on each wizard edit (debounced); cleared on Save/Cancel; restored if the user returns to an unfinished wizard. Survives app kill.
- **Export:** serialize the profile to JSON → write `<name>.echobugprofile` (JSON) → share via the OS share sheet. Paths are included but flagged as device-local.
- **Import:** pick a `.echobugprofile`/`.json` → deserialize → new id + timestamps. **If `musicFilePath`/`calibrationVoiceSamplePath` don't exist on this device, import succeeds but marks them missing and the wizard requires re-selecting music before the profile is usable** (edge case E5).

---

## 7. Preview generation strategy

1. Validate sample + music exist & supported (pre-flight).
2. Debounce control changes (~400 ms) so dragging a slider doesn't spawn renders.
3. Cancel any in-flight preview, then render trimmed 15 s to temp.
4. Show generation progress (reuse the stage/% stream).
5. On success, load + play via `just_audio`; expose play/pause/replay.
6. Delete temp preview on calibration-screen dispose (and Settings→Clear cache already removes `echobug_preview*`).

**Constant:** `previewDuration` is currently 15 s (spec says 15–30). Keep 15 s default for speed; configurable in `AppConstants`. (Decision Q4 covers exact length if you want 30.)

---

## 8. State management architecture

- `profileWizardControllerProvider` — `AutoDisposeNotifier<WizardState>`; holds the draft `BackgroundProfile`, `currentStep`, validation, and persists draft via `draft_usecases` (auto-save). Seeded from an existing profile when editing.
- `calibrationPreviewControllerProvider` — `AutoDisposeNotifier<AsyncValue<PreviewState>>`; owns the `just_audio` player, current preview path, debounce + cancel.
- Reuses `profilesProvider`, `saveProfileUseCaseProvider`, `generatePreviewUseCaseProvider`, `filePickServiceProvider`, `audioProcessorProvider`.
- Widgets stay logic-free: they read controllers and call use cases.

---

## 9. Edge cases

- **E1** Music/sample path moved or deleted → probe fails → inline "file missing, re-select" (block Preview/Save until fixed).
- **E2** Corrupt/unsupported file → `CorruptFileFailure`/`UnsupportedFormatFailure` message.
- **E3** Rapid slider changes → debounce + cancel-prior-preview (no render pileup).
- **E4** Preview tapped with no sample selected → Preview disabled until Step 3 done.
- **E5** Imported profile with absent files → usable config, but music re-selection forced before production use.
- **E6** **Container mismatch (important):** the calibration preview uses the *sample's* container; a future production file may have a different container. DSP/mix/loudness (what's being calibrated) are container-independent, so the sound is representative — but exact codec/extension follows the real production file (mirror-source, existing decision). Documented so expectations are right.
- **E7** Voice-only profile (no music) → allowed; preview/skip the mix branch (builder already handles it).
- **E8** App killed mid-wizard → draft restored from the draft box.
- **E9** Very long sample/music → preview trims to 15 s; production handles up to 60 min (verified 14.2× realtime).
- **E10** Delete profile → confirm dialog (already implemented).

---

## 10. Implementation plan (phased, each ends green: analyze + tests)

| CP | Deliverable | Verify |
|----|-------------|--------|
| **CP1** | Entity +`description`+`calibrationVoiceSamplePath`; Hive model fields 13/14; mappers; freezed regen; JSON for export/import | host unit: round-trip + backward-compat read |
| **CP2** | Wizard scaffold: 4-step PageView, `WizardState` controller, step nav, draft auto-save box + restore | host unit: draft save/load; widget: steps render |
| **CP3** | Step 4 Calibrate UI: all controls bound to draft (reuse editor widgets), values beside sliders, estimated-output summary | widget test |
| **CP4** | Live preview: reuse `GeneratePreviewUseCase` with sample+draft, just_audio playback, debounce, cancel-prior, progress | **on-device**: preview renders + plays |
| **CP5** | Export/Import profile (JSON `.echobugprofile`, share sheet, missing-file handling) + edit loads into wizard | host unit: serialize/deserialize; device: round-trip |
| **CP6** | *(Optional)* Waveform via FFmpeg peak extraction + CustomPainter | device: renders for a sample |
| **CP7** | Profiles screen wiring (FAB→wizard, Calibrate action, import button); retire flat editor route | analyze + walkthrough |
| **CP8** | Full on-device calibration walkthrough (create→calibrate→preview→iterate→save→use in Apply) | device integration test |

Main-app Apply integration needs **no change** — it already consumes every profile field and is device-verified.

---

## 11. Decisions — APPROVED (2026-06-15)

- **Q1 ✅ Replace** the flat Profile Editor with the guided wizard (create + edit).
- **Q2 ✅ Defer waveform** — optional later polish (CP6 dropped from this round).
- **Q3 ✅ Keep enums** — JSON export serializes them as readable strings.
- **Q4 ✅ Share sheet** (`share_plus`) for `.echobugprofile` JSON; **preview = 15 s**.

Build order: CP1 → CP2 → CP3 → CP4 → CP5 → CP7 → CP8 (CP6 waveform deferred).
```
