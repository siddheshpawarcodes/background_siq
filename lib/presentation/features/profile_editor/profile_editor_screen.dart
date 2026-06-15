import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/enums.dart';

/// Profile editor — all profile fields (SRS §11.4).
///
/// Transient form state lives in this widget; validation and persistence are
/// delegated to [SaveProfileUseCase], keeping business logic out of the UI.
class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({super.key, this.profileId});

  /// Null when creating a new profile.
  final String? profileId;

  @override
  ConsumerState<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  late BackgroundProfile _draft;
  late final TextEditingController _nameController;
  bool _saving = false;

  bool get _isNew => widget.profileId == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.profileId == null
        ? null
        : ref.read(profileRepositoryProvider).getByIdSync(widget.profileId!);
    _draft = existing ?? _newDraft();
    _nameController = TextEditingController(text: _draft.name);
  }

  BackgroundProfile _newDraft() {
    final now = DateTime.now();
    return BackgroundProfile(
      id: const Uuid().v4(),
      name: '',
      createdDate: now,
      modifiedDate: now,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickMusic() async {
    final path = await ref.read(filePickServiceProvider).pickAudioPath();
    if (path != null) setState(() => _draft = _draft.copyWith(musicFilePath: path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(saveProfileUseCaseProvider)
        .call(_draft.copyWith(name: _nameController.text));
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (_) => Navigator.of(context).pop(),
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Profile' : 'Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Profile name',
              hintText: 'e.g. Corporate',
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: Spacing.lg),
          _musicPicker(),
          const SizedBox(height: Spacing.lg),
          _slider(
            label: 'Music volume',
            value: _draft.musicVolume.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            display: '${_draft.musicVolume}%',
            onChanged: (v) => setState(() => _draft = _draft.copyWith(musicVolume: v.round())),
          ),
          const SizedBox(height: Spacing.md),
          _label('Noise reduction'),
          SegmentedButton<NoiseLevel>(
            segments: [
              for (final n in NoiseLevel.values)
                ButtonSegment(value: n, label: Text(n.label)),
            ],
            selected: {_draft.noiseReduction},
            onSelectionChanged: (s) =>
                setState(() => _draft = _draft.copyWith(noiseReduction: s.first)),
          ),
          const SizedBox(height: Spacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Voice enhancement'),
            subtitle: const Text('Speech EQ, compression, presence'),
            value: _draft.voiceEnhancementEnabled,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(voiceEnhancementEnabled: v)),
          ),
          const SizedBox(height: Spacing.sm),
          _label('Ducking'),
          SegmentedButton<DuckingStrength>(
            segments: [
              for (final d in DuckingStrength.values)
                ButtonSegment(value: d, label: Text(d.label)),
            ],
            selected: {_draft.ducking},
            onSelectionChanged: (s) =>
                setState(() => _draft = _draft.copyWith(ducking: s.first)),
          ),
          const SizedBox(height: Spacing.md),
          _slider(
            label: 'Fade in',
            value: _draft.fadeInSeconds,
            min: 0,
            max: 10,
            divisions: 20,
            display: '${_draft.fadeInSeconds.toStringAsFixed(1)}s',
            onChanged: (v) => setState(() => _draft = _draft.copyWith(fadeInSeconds: v)),
          ),
          _slider(
            label: 'Fade out',
            value: _draft.fadeOutSeconds,
            min: 0,
            max: 10,
            divisions: 20,
            display: '${_draft.fadeOutSeconds.toStringAsFixed(1)}s',
            onChanged: (v) => setState(() => _draft = _draft.copyWith(fadeOutSeconds: v)),
          ),
          const SizedBox(height: Spacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loudness normalization'),
            subtitle: const Text('Consistent volume, no clipping'),
            value: _draft.normalizationEnabled,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(normalizationEnabled: v)),
          ),
          const SizedBox(height: Spacing.sm),
          _label('Output format'),
          SegmentedButton<ExportFormat>(
            segments: [
              for (final f in ExportFormat.values)
                ButtonSegment(value: f, label: Text(f.label)),
            ],
            selected: {_draft.exportFormat},
            onSelectionChanged: (s) =>
                setState(() => _draft = _draft.copyWith(exportFormat: s.first)),
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save profile'),
          ),
        ],
      ),
    );
  }

  Widget _musicPicker() {
    final path = _draft.musicFilePath;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(path == null ? 'No background music' : p.basename(path)),
        subtitle: Text(path == null ? 'Tap to choose a track' : 'Tap to change'),
        trailing: path == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () =>
                    setState(() => _draft = _draft.copyWith(musicFilePath: null)),
              ),
        onTap: _pickMusic,
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(display),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: display,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
