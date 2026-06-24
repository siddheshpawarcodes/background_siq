import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
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

    // Confirm to the user once a Refresh finishes rendering (design §4).
    ref.listen(calibrationPreviewControllerProvider, (prev, next) {
      if (prev?.status == PreviewStatus.refreshing &&
          next.status == PreviewStatus.ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview updated successfully')),
        );
      }
    });

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
        Spacing.md.verticalSpace,
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
        Spacing.md.verticalSpace,
        _label(context, 'Noise reduction'),
        SegmentedButton<NoiseLevel>(
          segments: [
            for (final n in NoiseLevel.values)
              ButtonSegment(value: n, label: Text(n.label)),
          ],
          selected: {draft.noiseReduction},
          onSelectionChanged: (s) => ctrl.setNoise(s.first),
        ),
        Spacing.md.verticalSpace,
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Voice enhancement'),
          subtitle: const Text('Speech EQ, compression, presence'),
          value: draft.voiceEnhancementEnabled,
          onChanged: ctrl.setEnhancement,
        ),
        Spacing.sm.verticalSpace,
        _label(context, 'Tone EQ'),
        _sliderRow(
          context,
          label: 'Bass',
          display: _db(draft.eqBassDb),
          value: draft.eqBassDb,
          min: -12,
          max: 12,
          divisions: 24,
          onChanged: ctrl.setEqBass,
        ),
        _sliderRow(
          context,
          label: 'Mid',
          display: _db(draft.eqMidDb),
          value: draft.eqMidDb,
          min: -12,
          max: 12,
          divisions: 24,
          onChanged: ctrl.setEqMid,
        ),
        _sliderRow(
          context,
          label: 'Treble',
          display: _db(draft.eqTrebleDb),
          value: draft.eqTrebleDb,
          min: -12,
          max: 12,
          divisions: 24,
          onChanged: ctrl.setEqTreble,
        ),
        Spacing.md.verticalSpace,
        _label(context, 'Ducking'),
        SegmentedButton<DuckingStrength>(
          segments: [
            for (final d in DuckingStrength.values)
              ButtonSegment(value: d, label: Text(d.label)),
          ],
          selected: {draft.ducking},
          onSelectionChanged: (s) => ctrl.setDucking(s.first),
        ),
        Spacing.md.verticalSpace,
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
        if (draft.exportFormat != ExportFormat.wav) ...[
          Spacing.md.verticalSpace,
          _label(context, 'Bitrate'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 128, label: Text('128k')),
              ButtonSegment(value: 192, label: Text('192k')),
              ButtonSegment(value: 256, label: Text('256k')),
              ButtonSegment(value: 320, label: Text('320k')),
            ],
            selected: {_effectiveBitrate(draft)},
            onSelectionChanged: (s) => ctrl.setBitrate(s.first),
          ),
        ],
        Spacing.md.verticalSpace,
        _estimatedOutput(context, draft),
      ],
    );
  }

  /// The professional preview panel (design §2–§5, §7). Renders strictly from
  /// [preview].status so the controls and the audio engine can never desync; the
  /// out-of-date badge is layered on top by comparing the live draft against the
  /// rendered preview's settings.
  Widget _previewBar(
    BuildContext context,
    WidgetRef ref,
    BackgroundProfile draft,
    PreviewState preview,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(calibrationPreviewControllerProvider.notifier);
    final sample = draft.calibrationVoiceSamplePath;
    final outOfDate = preview.hasPreview && notifier.isStale(draft);

    final Widget body;
    switch (preview.status) {
      case PreviewStatus.idle:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sample == null
                  ? 'Add a calibration voice sample (Step 3) to preview.'
                  : 'Generate a preview to hear your settings applied to the '
                      'sample.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Spacing.sm.verticalSpace,
            FilledButton.icon(
              onPressed: sample == null ? null : () => notifier.generate(draft),
              icon: const Icon(Icons.graphic_eq),
              label: const Text('Generate Preview'),
            ),
          ],
        );
      case PreviewStatus.generating:
        body = _loadingRow(context, 'Generating preview…');
      case PreviewStatus.refreshing:
        body = _loadingRow(context, 'Refreshing preview…');
      case PreviewStatus.error:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.error ?? 'Preview failed.',
              style: TextStyle(color: scheme.error),
            ),
            Spacing.sm.verticalSpace,
            OutlinedButton.icon(
              onPressed: sample == null ? null : () => notifier.generate(draft),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        );
      case PreviewStatus.ready:
      case PreviewStatus.playing:
      case PreviewStatus.paused:
      case PreviewStatus.stopped:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filled(
                  onPressed: notifier.togglePlay,
                  tooltip: preview.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(preview.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
                Spacing.sm.horizontalSpace,
                IconButton.filledTonal(
                  onPressed: notifier.stop,
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => notifier.refresh(draft),
                  tooltip: 'Refresh preview',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            Spacing.xs.verticalSpace,
            AudioSeekBar(
              positionStream: notifier.positionStream,
              durationStream: notifier.durationStream,
              onSeek: notifier.seek,
            ),
            if (outOfDate) ...[
              Spacing.sm.verticalSpace,
              _outOfDateBadge(context, () => notifier.refresh(draft)),
            ],
          ],
        );
    }

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.equalizer,
                    size: 18, color: scheme.onPrimaryContainer),
                Spacing.xs.horizontalSpace,
                Text('Preview',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            Spacing.sm.verticalSpace,
            body,
          ],
        ),
      ),
    );
  }

  Widget _loadingRow(BuildContext context, String text) => Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          Spacing.sm.horizontalSpace,
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );

  /// Warning shown when DSP settings changed after the preview was rendered, so
  /// the user can't mistake the loaded clip for the latest configuration.
  Widget _outOfDateBadge(BuildContext context, VoidCallback onRefresh) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Spacing.sm, Spacing.xs, Spacing.xs, Spacing.xs),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: scheme.onErrorContainer),
          Spacing.xs.horizontalSpace,
          Expanded(
            child: Text(
              'Preview needs regeneration',
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
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
      if (draft.eqBassDb != 0 || draft.eqMidDb != 0 || draft.eqTrebleDb != 0)
        'EQ: ${_db(draft.eqBassDb)} / ${_db(draft.eqMidDb)} / ${_db(draft.eqTrebleDb)}',
      'Format: ${draft.exportFormat.label}',
      if (draft.exportFormat != ExportFormat.wav) 'Bitrate: ${_effectiveBitrate(draft)}k',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated output settings',
                style: Theme.of(context).textTheme.titleSmall),
            Spacing.xs.verticalSpace,
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

  /// Signed dB display for an EQ band ("+3 dB", "0 dB", "-2 dB").
  String _db(double v) =>
      v == 0 ? '0 dB' : '${v > 0 ? '+' : ''}${v.toStringAsFixed(0)} dB';

  /// Bitrate currently in effect for the lossy-format selector: the explicit
  /// override if set, else the per-codec default the engine would use.
  int _effectiveBitrate(BackgroundProfile draft) =>
      draft.audioBitrateKbps ?? (draft.exportFormat == ExportFormat.aac ? 256 : 320);

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
