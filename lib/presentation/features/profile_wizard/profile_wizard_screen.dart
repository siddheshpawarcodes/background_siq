import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/audio_file_card.dart';
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

  static const _titles = ['Profile info', 'Background music', 'Calibration sample', 'Calibrate'];

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

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Profile' : 'Edit Profile'),
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
        WizardStep.music =>
          _musicStep(state.draft.musicFilePath, state.draft.coverImagePath),
        WizardStep.sample => _sampleStep(state.draft.calibrationVoiceSamplePath),
        _ => CalibrateStep(profileId: widget.profileId),
      },
      bottomNavigationBar: _navBar(state.step, state.draft.name.trim().isNotEmpty),
    );
  }

  Widget _infoStep() => ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Profile name',
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

  Widget _musicStep(String? path, String? coverPath) => Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AudioFileCard(
              icon: Icons.music_note,
              emptyTitle: 'No background music',
              emptySubtitle: 'Tap to choose a track (optional)',
              path: path,
              onPick: () async {
                final picked = await ref.read(filePickServiceProvider).pickAudioPath();
                if (picked != null) _ctrl.setMusic(picked);
              },
              onClear: () => _ctrl.setMusic(null),
            ),
            Spacing.md.verticalSpace,
            _coverCard(coverPath),
          ],
        ),
      );

  Widget _coverCard(String? path) {
    final exists = path != null && File(path).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            leading: exists
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(File(path),
                        width: 40, height: 40, fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_outlined),
            title: Text(path == null ? 'No cover image (thumbnail)' : p.basename(path),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(path == null
                ? 'Tap to choose a JPG or PNG (optional)'
                : (exists ? 'Tap to change' : 'File missing — tap to re-select')),
            trailing: path == null
                ? const Icon(Icons.folder_open)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _ctrl.setCover(null),
                  ),
            onTap: () async {
              final picked = await ref.read(filePickServiceProvider).pickImagePath();
              if (picked != null) _ctrl.setCover(picked);
            },
          ),
        ),
        if (path != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm, left: Spacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Theme.of(context).colorScheme.outline),
                Spacing.sm.horizontalSpace,
                Expanded(
                  child: Text(
                    'The thumbnail is embedded only when exporting to '
                    '${AppConstants.coverArtCapableLabel}. WAV and OGG files '
                    "can't store a cover image, so it will be skipped for those.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

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
          ],
        ),
      );

  Widget _navBar(int step, bool nameValid) {
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
                    : (step == WizardStep.info && !nameValid ? null : _ctrl.next),
                child: Text(isLast ? 'Save profile' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
