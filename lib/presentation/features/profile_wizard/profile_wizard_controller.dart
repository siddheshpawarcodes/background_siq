import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/result/result.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/enums.dart';

/// Wizard step indices.
class WizardStep {
  static const info = 0;
  static const music = 1;
  static const sample = 2;
  static const calibrate = 3;
  static const count = 4;
}

class WizardState {
  const WizardState({required this.draft, this.step = 0});
  final BackgroundProfile draft;
  final int step;

  WizardState copyWith({BackgroundProfile? draft, int? step}) =>
      WizardState(draft: draft ?? this.draft, step: step ?? this.step);
}

/// Drives the Profile Creation/Edit wizard (design §8). Holds the draft profile
/// and auto-saves it (debounced) for NEW profiles so progress survives an app
/// kill. Edit mode seeds from the real profile and does not touch the draft slot.
final profileWizardControllerProvider = NotifierProvider.autoDispose
    .family<ProfileWizardController, WizardState, String?>(
  ProfileWizardController.new,
);

class ProfileWizardController
    extends AutoDisposeFamilyNotifier<WizardState, String?> {
  Timer? _debounce;

  bool get _isNew => arg == null;

  @override
  WizardState build(String? arg) {
    ref.onDispose(() => _debounce?.cancel());
    final BackgroundProfile draft;
    if (arg != null) {
      draft = ref.read(profileRepositoryProvider).getByIdSync(arg) ?? _new();
    } else {
      draft = ref.read(draftRepositoryProvider).load() ?? _new();
    }
    return WizardState(draft: draft);
  }

  BackgroundProfile _new() {
    final now = DateTime.now();
    return BackgroundProfile(
      id: const Uuid().v4(),
      name: '',
      createdDate: now,
      modifiedDate: now,
    );
  }

  void _update(BackgroundProfile draft) {
    state = state.copyWith(draft: draft);
    if (_isNew) _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(draftRepositoryProvider).save(state.draft);
    });
  }

  // --- Field setters ---
  void setName(String v) => _update(state.draft.copyWith(name: v));
  void setDescription(String v) => _update(state.draft.copyWith(description: v));
  void setMusic(String? path) => _update(state.draft.copyWith(musicFilePath: path));
  void setCalibrationSample(String? path) =>
      _update(state.draft.copyWith(calibrationVoiceSamplePath: path));
  void setVolume(int v) => _update(state.draft.copyWith(musicVolume: v));
  void setNoise(NoiseLevel v) => _update(state.draft.copyWith(noiseReduction: v));
  void setEnhancement(bool v) =>
      _update(state.draft.copyWith(voiceEnhancementEnabled: v));
  void setDucking(DuckingStrength v) => _update(state.draft.copyWith(ducking: v));
  void setFadeIn(double v) => _update(state.draft.copyWith(fadeInSeconds: v));
  void setFadeOut(double v) => _update(state.draft.copyWith(fadeOutSeconds: v));
  void setNormalization(bool v) =>
      _update(state.draft.copyWith(normalizationEnabled: v));
  void setFormat(ExportFormat v) => _update(state.draft.copyWith(exportFormat: v));

  // --- Navigation ---
  void goTo(int step) => state = state.copyWith(step: step.clamp(0, WizardStep.count - 1));
  void next() => goTo(state.step + 1);
  void back() => goTo(state.step - 1);

  // --- Persistence ---
  Future<Result<void>> saveProfile() async {
    final result = await ref.read(saveProfileUseCaseProvider).call(state.draft);
    if (result.isOk && _isNew) await ref.read(draftRepositoryProvider).clear();
    return result;
  }

  Future<void> discardDraft() async {
    if (_isNew) await ref.read(draftRepositoryProvider).clear();
  }
}
