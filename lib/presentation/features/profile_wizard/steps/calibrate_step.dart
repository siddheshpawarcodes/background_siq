import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/audio_file_ref.dart';
import '../../../../domain/entities/background_profile.dart';
import '../../../../domain/entities/enums.dart';
import '../../../shared/audio_seek_bar.dart';
import '../calibration_preview_controller.dart';
import '../profile_wizard_controller.dart';

/// Step 4 — the calibration screen: all DSP controls bound to the draft, plus
/// the live Preview button (design §4, §7). Logic lives in the controllers.
class CalibrateStep extends ConsumerWidget {
  const CalibrateStep({super.key, required this.profileId});

  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(profileWizardControllerProvider(profileId).notifier);
    final draft = ref.watch(profileWizardControllerProvider(profileId)).draft;
    final preview = ref.watch(calibrationPreviewControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        _previewBar(context, ref, draft, preview),
        const Divider(height: Spacing.xl),
        _sliderRow(
          context,
          label: 'Audio volume',
          display: '${draft.voiceVolume}%',
          value: draft.voiceVolume.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (v) => ctrl.setVoiceVolume(v.round()),
        ),
        const SizedBox(height: Spacing.md),
        _sliderRow(
          context,
          label: 'Background music volume',
          display: '${draft.musicVolume}%',
          value: draft.musicVolume.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (v) => ctrl.setVolume(v.round()),
        ),
        const SizedBox(height: Spacing.md),
        _label(context, 'Noise reduction'),
        SegmentedButton<NoiseLevel>(
          segments: [
            for (final n in NoiseLevel.values)
              ButtonSegment(value: n, label: Text(n.label)),
          ],
          selected: {draft.noiseReduction},
          onSelectionChanged: (s) => ctrl.setNoise(s.first),
        ),
        const SizedBox(height: Spacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Voice enhancement'),
          subtitle: const Text('Speech EQ, compression, presence'),
          value: draft.voiceEnhancementEnabled,
          onChanged: ctrl.setEnhancement,
        ),
        _label(context, 'Ducking'),
        SegmentedButton<DuckingStrength>(
          segments: [
            for (final d in DuckingStrength.values)
              ButtonSegment(value: d, label: Text(d.label)),
          ],
          selected: {draft.ducking},
          onSelectionChanged: (s) => ctrl.setDucking(s.first),
        ),
        const SizedBox(height: Spacing.md),
        _sliderRow(
          context,
          label: 'Fade in',
          display: '${draft.fadeInSeconds.toStringAsFixed(1)}s',
          value: draft.fadeInSeconds,
          min: 0,
          max: 10,
          divisions: 20,
          onChanged: ctrl.setFadeIn,
        ),
        _sliderRow(
          context,
          label: 'Fade out',
          display: '${draft.fadeOutSeconds.toStringAsFixed(1)}s',
          value: draft.fadeOutSeconds,
          min: 0,
          max: 10,
          divisions: 20,
          onChanged: ctrl.setFadeOut,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Loudness normalization'),
          subtitle: const Text('Consistent volume, no clipping'),
          value: draft.normalizationEnabled,
          onChanged: ctrl.setNormalization,
        ),
        _label(context, 'Output format'),
        SegmentedButton<ExportFormat>(
          segments: [
            for (final f in ExportFormat.values)
              ButtonSegment(value: f, label: Text(f.label)),
          ],
          selected: {draft.exportFormat},
          onSelectionChanged: (s) => ctrl.setFormat(s.first),
        ),
        const SizedBox(height: Spacing.md),
        _estimatedOutput(context, draft),
      ],
    );
  }

  Widget _previewBar(
    BuildContext context,
    WidgetRef ref,
    BackgroundProfile draft,
    PreviewState preview,
  ) {
    final sample = draft.calibrationVoiceSamplePath;
    final canPreview = sample != null && !preview.generating;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live preview',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.xs),
            Text(
              sample == null
                  ? 'Add a calibration voice sample (Step 3) to preview.'
                  : 'Hear your settings applied to the sample.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (preview.error != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(preview.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                FilledButton.icon(
                  // Disabled (greyed out) while a preview renders; no spinner —
                  // the seek bar + autoplay appear only once rendering completes.
                  onPressed: canPreview
                      ? () => ref
                          .read(calibrationPreviewControllerProvider.notifier)
                          .preview(
                            AudioFileRef(
                              path: sample,
                              name: sample.split('/').last,
                              ext: sample.split('.').last.toLowerCase(),
                            ),
                            draft,
                          )
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Preview'),
                ),
                if (preview.hasPreview && !preview.generating) ...[
                  const SizedBox(width: Spacing.sm),
                  IconButton(
                    onPressed: () => ref
                        .read(calibrationPreviewControllerProvider.notifier)
                        .togglePlay(),
                    icon: Icon(preview.playing ? Icons.pause : Icons.play_arrow),
                  ),
                ],
              ],
            ),
            if (preview.hasPreview && !preview.generating) ...[
              const SizedBox(height: Spacing.xs),
              Builder(builder: (context) {
                final ctrl =
                    ref.read(calibrationPreviewControllerProvider.notifier);
                return AudioSeekBar(
                  positionStream: ctrl.positionStream,
                  durationStream: ctrl.durationStream,
                  onSeek: ctrl.seek,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _estimatedOutput(BuildContext context, BackgroundProfile draft) {
    final lines = [
      'Audio: ${draft.voiceVolume}%',
      'Music: ${draft.musicFilePath == null ? 'none' : '${draft.musicVolume}%'}',
      'Noise: ${draft.noiseReduction.label}',
      'Ducking: ${draft.ducking.label}',
      'Enhance: ${draft.voiceEnhancementEnabled ? 'on' : 'off'}',
      'Normalize: ${draft.normalizationEnabled ? 'on' : 'off'}',
      'Format: ${draft.exportFormat.label}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated output settings',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.xs),
            Text(lines.join('  ·  '),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _sliderRow(
    BuildContext context, {
    required String label,
    required String display,
    required double value,
    required double min,
    required double max,
    required int divisions,
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
