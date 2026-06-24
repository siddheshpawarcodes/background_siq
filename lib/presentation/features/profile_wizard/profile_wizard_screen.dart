import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/audio_file_card.dart';
import '../../shared/navigation/navigation_guard.dart';
import 'profile_wizard_controller.dart';
import 'steps/calibrate_step.dart';

/// Guided Profile Creation/Edit wizard (design §4). Hosts 4 steps; transient
/// text-field state is local, all profile state lives in the controller.
class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key, this.profileId});

  /// Null = create; non-null = edit an existing profile.
  final String? profileId;

  @override
  ConsumerState<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;

  static const _titles = ['Backdrop info', 'Background music', 'Calibration sample', 'Calibrate'];

  ProfileWizardController get _ctrl =>
      ref.read(profileWizardControllerProvider(widget.profileId).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(profileWizardControllerProvider(widget.profileId)).draft;
    _name = TextEditingController(text: draft.name);
    _description = TextEditingController(text: draft.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileWizardControllerProvider(widget.profileId));
    final isNew = widget.profileId == null;

    return NavigationGuard(
      // Block accidental exits while there are unsaved edits; the guard drives
      // the actual pop (design §6). A successful Save pops imperatively, which
      // bypasses the guard, so it is never intercepted.
      debugLabel: 'profile-wizard',
      canPop: !_ctrl.hasUnsavedChanges,
      onConfirmLeave: () async {
        final discard = await _confirmDiscard();
        if (discard != true) return false;
        await _ctrl.discardDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'New Backdrop' : 'Edit Backdrop'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step ${state.step + 1} of ${WizardStep.count} · ${_titles[state.step]}'),
                  Spacing.xs.verticalSpace,
                  LinearProgressIndicator(value: (state.step + 1) / WizardStep.count),
                ],
              ),
            ),
          ),
        ),
        body: switch (state.step) {
          WizardStep.info => _infoStep(),
          WizardStep.music => _musicStep(state.draft.musicFilePath),
          WizardStep.sample => _sampleStep(state.draft.calibrationVoiceSamplePath),
          _ => CalibrateStep(profileId: widget.profileId),
        },
        bottomNavigationBar: _navBar(state),
      ),
    );
  }

  Widget _infoStep() => ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Backdrop name',
              hintText: 'e.g. Corporate Intro',
            ),
            onChanged: _ctrl.setName,
          ),
          Spacing.md.verticalSpace,
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g. Used for customer training videos',
            ),
            maxLines: 3,
            onChanged: _ctrl.setDescription,
          ),
        ],
      );

  Widget _musicStep(String? path) => Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AudioFileCard(
              icon: Icons.music_note,
              emptyTitle: 'No background music',
              emptySubtitle: 'Tap to choose a track',
              path: path,
              onPick: () async {
                final picked = await ref.read(filePickServiceProvider).pickAudioPath();
                if (picked != null) _ctrl.setMusic(picked);
              },
              onClear: () => _ctrl.setMusic(null),
            ),
            _validationMessage(
              path: path,
              missingMessage: 'Please select a background music track to continue.',
              unavailableMessage:
                  'The selected music file is no longer available. Choose another to continue.',
            ),
          ],
        ),
      );

  Widget _sampleStep(String? path) => Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick a sample voice recording. It is used only to calibrate and '
              'preview — it is never part of your exported files.',
            ),
            Spacing.md.verticalSpace,
            AudioFileCard(
              icon: Icons.record_voice_over,
              emptyTitle: 'No calibration sample',
              emptySubtitle: 'Tap to choose a voice recording',
              path: path,
              onPick: () async {
                final picked = await ref.read(filePickServiceProvider).pickAudioPath();
                if (picked != null) _ctrl.setCalibrationSample(picked);
              },
              onClear: () => _ctrl.setCalibrationSample(null),
            ),
            _validationMessage(
              path: path,
              missingMessage: 'Please select a calibration voice sample to continue.',
              unavailableMessage:
                  'The selected sample is no longer available. Choose another to continue.',
            ),
          ],
        ),
      );

  /// Inline validation under a mandatory file step: prompts to pick a file when
  /// none is set, or flags an error when the chosen file has gone missing.
  Widget _validationMessage({
    required String? path,
    required String missingMessage,
    required String unavailableMessage,
  }) {
    if (_fileReady(path)) return const SizedBox.shrink();
    final message = path == null ? missingMessage : unavailableMessage;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.error),
          Spacing.xs.horizontalSpace,
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _navBar(WizardState state) {
    final step = state.step;
    final isLast = step == WizardStep.count - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            if (step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _ctrl.back,
                  child: const Text('Back'),
                ),
              ),
            if (step > 0) Spacing.md.horizontalSpace,
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: isLast
                    ? _save
                    : (_stepValid(state) ? _ctrl.next : null),
                child: Text(isLast ? 'Save backdrop' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Whether the current step satisfies its requirements to advance. Music and
  /// the calibration sample are mandatory and must point at a readable file
  /// (design §1).
  bool _stepValid(WizardState state) {
    switch (state.step) {
      case WizardStep.info:
        return state.draft.name.trim().isNotEmpty;
      case WizardStep.music:
        return _fileReady(state.draft.musicFilePath);
      case WizardStep.sample:
        return _fileReady(state.draft.calibrationVoiceSamplePath);
      default:
        return true;
    }
  }

  /// A non-null path that still resolves to an existing file on disk.
  bool _fileReady(String? path) => path != null && File(path).existsSync();

  Future<bool?> _confirmDiscard() => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved backdrop changes.\n'
            'Do you want to leave this screen or continue editing?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard Changes'),
            ),
          ],
        ),
      );

  Future<void> _save() async {
    final result = await _ctrl.saveProfile();
    if (!mounted) return;
    result.fold(
      (_) => Navigator.of(context).pop(),
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}
