import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/background_profile.dart';
import '../processing/processing_queue_controller.dart';

/// Record tab — capture audio, preview it on a scrubbable full-clip waveform,
/// attach a profile, and hand the edit to the background queue so the user can
/// immediately record again while the previous clip is processed.
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

/// Where the user is in the record → preview → hand-off flow.
enum _Phase { idle, recording, paused, preview }

/// Waveform bar density used for the preview extraction. Independent of clip
/// length (bars scale with duration), so longer clips simply scroll further.
const int _kWaveSamplesPerSecond = 80;

const _uuid = Uuid();

class _RecordScreenState extends ConsumerState<RecordScreen> {
  final RecorderController _recorder = RecorderController();
  PlayerController? _player;
  StreamSubscription<void>? _completionSub;

  _Phase _phase = _Phase.idle;
  String? _recordedPath;
  String? _profileId;
  bool _busy = false; // guards async start/stop transitions

  @override
  void dispose() {
    _completionSub?.cancel();
    _recorder.dispose();
    _player?.dispose();
    super.dispose();
  }

  // --- Recording lifecycle ---

  Future<void> _startRecording() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final granted = await _recorder.checkPermission();
      if (!granted) {
        _toast('Microphone permission is required to record.');
        return;
      }
      await _recorder.record(path: await _newRecordingPath());
      if (mounted) setState(() => _phase = _Phase.recording);
    } catch (e) {
      _toast('Could not start recording: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    if (mounted) setState(() => _phase = _Phase.paused);
  }

  Future<void> _resumeRecording() async {
    await _recorder.record(); // resumes from where it paused
    if (mounted) setState(() => _phase = _Phase.recording);
  }

  Future<void> _stopRecording() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await _recorder.stop();
      if (path == null) {
        _toast('Recording was empty.');
        if (mounted) setState(() => _phase = _Phase.idle);
        return;
      }
      await _preparePreview(path);
    } catch (e) {
      _toast('Could not finish recording: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preparePreview(String path) async {
    final player = PlayerController();
    await player.preparePlayer(
      path: path,
      shouldExtractWaveform: true,
      noOfSamplesPerSecond: _kWaveSamplesPerSecond,
    );
    // Pause (not dispose) at the end so the clip can be auditioned repeatedly;
    // rewind on completion so the next tap plays from the start.
    await player.setFinishMode(finishMode: FinishMode.pause);
    _completionSub = player.onCompletion.listen((_) => player.seekTo(0));

    if (!mounted) {
      player.dispose();
      return;
    }
    setState(() {
      _player = player;
      _recordedPath = path;
      _phase = _Phase.preview;
    });
  }

  /// Discards the current take and returns to a fresh recording state.
  void _discard() {
    _completionSub?.cancel();
    _completionSub = null;
    _player?.dispose();
    _player = null;
    _recordedPath = null;
    setState(() => _phase = _Phase.idle);
  }

  // --- Hand-off to the background queue ---

  void _processInBackground(BackgroundProfile profile) {
    final path = _recordedPath;
    if (path == null) return;
    ref
        .read(processingQueueProvider.notifier)
        .enqueue(_refFor(path, profile), profile);
    _toast('Added “${profile.name}” edit to the background queue.');
    // Reset so the user can record again immediately; the enqueued edit keeps
    // running in the background (the file lives on its own path).
    _discard();
    setState(() => _profileId = null);
  }

  AudioFileRef _refFor(String path, BackgroundProfile profile) {
    final ms = _player?.maxDuration ?? 0;
    return AudioFileRef(
      path: path,
      name: p.basename(path),
      ext: p.extension(path).replaceFirst('.', '').toLowerCase(),
      duration: ms > 0 ? Duration(milliseconds: ms) : null,
    );
  }

  Future<String> _newRecordingPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory(p.join(dir.path, 'recordings'));
    if (!await recDir.exists()) await recDir.create(recursive: true);
    return p.join(recDir.path, 'rec_${_uuid.v4()}.m4a');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: switch (_phase) {
            _Phase.idle => _idleView(),
            _Phase.recording || _Phase.paused => _recordingView(),
            _Phase.preview => _previewView(),
          },
        ),
      ),
    );
  }

  Widget _idleView() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Icon(Icons.graphic_eq, size: 64, color: scheme.primary),
        Spacing.md.verticalSpace,
        Text(
          'Record a new clip',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Spacing.sm.verticalSpace,
        Text(
          'Capture audio, preview it, then attach a profile to process in the '
          'background while you record the next one.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
        ),
        const Spacer(),
        _RecordButton(busy: _busy, onTap: _startRecording),
        Spacing.xl.verticalSpace,
      ],
    );
  }

  Widget _recordingView() {
    final scheme = Theme.of(context).colorScheme;
    final recording = _phase == _Phase.recording;
    return Column(
      children: [
        const Spacer(),
        StreamBuilder<Duration>(
          stream: _recorder.onCurrentDuration,
          builder: (context, snap) => Text(
            _fmt(snap.data ?? Duration.zero),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        Spacing.lg.verticalSpace,
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: AudioWaveforms(
            size: const Size(double.infinity, 120),
            recorderController: _recorder,
            enableGesture: false,
            waveStyle: WaveStyle(
              waveColor: scheme.primary,
              extendWaveform: true,
              showMiddleLine: false,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CircleAction(
              icon: recording ? Icons.pause : Icons.fiber_manual_record,
              color: recording ? scheme.secondary : scheme.error,
              tooltip: recording ? 'Pause' : 'Resume',
              onTap: recording ? _pauseRecording : _resumeRecording,
            ),
            _CircleAction(
              icon: Icons.stop,
              color: scheme.primary,
              tooltip: 'Stop',
              onTap: _busy ? null : _stopRecording,
            ),
          ],
        ),
        Spacing.xl.verticalSpace,
      ],
    );
  }

  Widget _previewView() {
    final player = _player;
    if (player == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final profilesAsync = ref.watch(profilesProvider);

    return ListView(
      children: [
        Text('Preview', style: Theme.of(context).textTheme.titleMedium),
        Spacing.sm.verticalSpace,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              children: [
                AudioFileWaveforms(
                  size: const Size(double.infinity, 100),
                  playerController: player,
                  waveformType: WaveformType.long,
                  enableSeekGesture: true,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: scheme.outlineVariant,
                    liveWaveColor: scheme.primary,
                    seekLineColor: scheme.primary,
                    spacing: 6,
                    showSeekLine: true,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Spacing.sm.verticalSpace,
                Row(
                  children: [
                    StreamBuilder<PlayerState>(
                      stream: player.onPlayerStateChanged,
                      builder: (context, snap) {
                        final playing =
                            (snap.data ?? player.playerState) ==
                            PlayerState.playing;
                        return IconButton(
                          iconSize: 40,
                          onPressed: _togglePlay,
                          icon: Icon(
                            playing ? Icons.pause_circle : Icons.play_circle,
                          ),
                        );
                      },
                    ),
                    Spacing.sm.horizontalSpace,
                    StreamBuilder<int>(
                      stream: player.onCurrentDurationChanged,
                      builder: (context, snap) {
                        final pos = Duration(milliseconds: snap.data ?? 0);
                        final total = Duration(
                          milliseconds: player.maxDuration,
                        );
                        return Text(
                          '${_fmt(pos)} / ${_fmt(total)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Spacing.lg.verticalSpace,
        profilesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Could not load profiles: $e'),
          data: (profiles) => _profileDropdown(profiles),
        ),
        Spacing.lg.verticalSpace,
        profilesAsync.maybeWhen(
          data: (profiles) => _actions(profiles),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _profileDropdown(List<BackgroundProfile> profiles) {
    return DropdownButtonFormField<String>(
      initialValue: _profileId,
      decoration: const InputDecoration(
        labelText: 'Background music profile',
        prefixIcon: Icon(Icons.tune),
      ),
      items: [
        for (final pr in profiles)
          DropdownMenuItem(value: pr.id, child: Text(pr.name)),
      ],
      onChanged: (id) => setState(() => _profileId = id),
    );
  }

  Widget _actions(List<BackgroundProfile> profiles) {
    BackgroundProfile? selected() {
      for (final pr in profiles) {
        if (pr.id == _profileId) return pr;
      }
      return null;
    }

    final profile = selected();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _discard,
            // icon: const Icon(Icons.replay),
            label: const Text('Re-record'),
          ),
        ),
        Spacing.md.horizontalSpace,
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: profile == null
                ? null
                : () => _processInBackground(profile),
            // icon: const Icon(Icons.auto_fix_high),
            label: const Text('Process in background'),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePlay() async {
    final player = _player;
    if (player == null) return;
    if (player.playerState == PlayerState.playing) {
      await player.pausePlayer();
    } else {
      await player.startPlayer();
    }
  }

  /// `M:SS`, or `H:MM:SS` past an hour.
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$s';
    return '$m:$s';
  }
}

/// Large circular record button shown on the idle screen.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Start recording',
      child: InkWell(
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(Icons.mic, size: 44, color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

/// Round control button used during recording (pause/resume/stop).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: onTap == null ? 0.3 : 1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}
