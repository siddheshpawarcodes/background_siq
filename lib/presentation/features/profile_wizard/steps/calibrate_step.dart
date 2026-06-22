import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/audio_file_ref.dart';
import '../../../../domain/entities/background_profile.dart';
import '../../../../domain/entities/enums.dart';
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
            Text('Live preview (first 15s)',
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
                  icon: preview.generating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(preview.generating ? 'Generating…' : 'Preview'),
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
              _PreviewSeekBar(
                controller:
                    ref.read(calibrationPreviewControllerProvider.notifier),
              ),
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

/// Real-time scrub bar for the live preview. Tracks the player's position via
/// [CalibrationPreviewController.positionStream] and lets the user seek. Local
/// [_dragValue] holds the thumb while dragging so position ticks don't fight the
/// gesture; it's committed on release.
class _PreviewSeekBar extends StatefulWidget {
  const _PreviewSeekBar({required this.controller});

  final CalibrationPreviewController controller;

  @override
  State<_PreviewSeekBar> createState() => _PreviewSeekBarState();
}

class _PreviewSeekBarState extends State<_PreviewSeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: widget.controller.durationStream,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: widget.controller.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final posMs = position.inMilliseconds.toDouble();
            final value = (_dragValue ?? posMs).clamp(0.0, maxMs <= 0 ? 1.0 : maxMs);
            final shown = _dragValue == null
                ? position
                : Duration(milliseconds: _dragValue!.round());
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: value,
                    max: maxMs <= 0 ? 1.0 : maxMs,
                    onChanged: maxMs <= 0
                        ? null
                        : (v) => setState(() => _dragValue = v),
                    onChangeEnd: maxMs <= 0
                        ? null
                        : (v) async {
                            await widget.controller
                                .seek(Duration(milliseconds: v.round()));
                            if (mounted) setState(() => _dragValue = null);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(shown),
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(_formatDuration(duration),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
