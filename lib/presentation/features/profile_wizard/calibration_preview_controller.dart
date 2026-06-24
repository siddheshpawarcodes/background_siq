import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/background_profile.dart';

/// Lifecycle of the calibration preview, modelled as a strict state machine so
/// the UI renders from a single source of truth and the audio engine never
/// drifts out of sync with the controls (design §7, preview reliability).
///
/// The spec's `PreviewState` enum lives here as [PreviewStatus]; the orthogonal
/// "out of date" flag is derived in the UI by comparing the live draft's
/// [dspSignature] against [CalibrationPreviewController.renderedSignature], since
/// a preview can be out of date in any of the playable states.
enum PreviewStatus {
  idle,
  generating,
  ready,
  playing,
  paused,
  stopped,
  refreshing,
  error,
}

class PreviewState {
  const PreviewState({this.status = PreviewStatus.idle, this.error});

  final PreviewStatus status;
  final String? error;

  /// A rendered clip is loaded in the player (regardless of play/pause/stop).
  /// While this is true the transport controls must stay on screen.
  bool get hasPreview =>
      status == PreviewStatus.ready ||
      status == PreviewStatus.playing ||
      status == PreviewStatus.paused ||
      status == PreviewStatus.stopped;

  /// A render (first generation or refresh) is in flight.
  bool get isBusy =>
      status == PreviewStatus.generating || status == PreviewStatus.refreshing;

  bool get isPlaying => status == PreviewStatus.playing;

  PreviewState copyWith({
    PreviewStatus? status,
    String? error,
    bool clearError = false,
  }) =>
      PreviewState(
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );
}

final calibrationPreviewControllerProvider =
    NotifierProvider.autoDispose<CalibrationPreviewController, PreviewState>(
  CalibrationPreviewController.new,
);

/// Renders a full-length preview of the draft profile against the calibration
/// sample. Generation never auto-plays — controls unlock only once a render
/// succeeds. Cancels any prior render before starting a new one so rapid
/// iteration never piles up native sessions (design §7, edge E3).
class CalibrationPreviewController extends AutoDisposeNotifier<PreviewState> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerSub;

  /// DSP signature of the profile behind the currently-loaded preview. Null
  /// until a render succeeds; the UI compares it against the live draft to flag
  /// the preview as out of date.
  String? _renderedSignature;
  String? get renderedSignature => _renderedSignature;

  /// Monotonic render ticket. Each render claims the next value; if a newer one
  /// starts while this is in flight, the stale result is dropped so overlapping
  /// renders can't fight over the state, player, or temp file.
  int _renderSeq = 0;

  bool _disposed = false;

  @override
  PreviewState build() {
    _player = AudioPlayer();
    _playerSub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        // Natural end of playback → rewind to the top and surface a stopped
        // state so the play button offers a fresh play-through.
        _player.pause();
        _player.seek(Duration.zero);
        if (!_disposed && state.hasPreview) {
          state = state.copyWith(status: PreviewStatus.stopped);
        }
      }
    });
    ref.onDispose(() {
      _disposed = true;
      _playerSub?.cancel();
      final usecase = ref.read(generatePreviewUseCaseProvider);
      usecase.cancelActive();
      _player.dispose();
      // Release the player handle (above) then drop the rendered temp file so
      // nothing lingers after Save / Discard / Back.
      usecase.clearPreviews();
    });
    return const PreviewState();
  }

  /// Builds the first preview for [draft] without auto-playing.
  Future<void> generate(BackgroundProfile draft) =>
      _render(draft, status: PreviewStatus.generating);

  /// Disposes the current clip and re-renders with the latest [draft] settings,
  /// resetting playback to the top (design §4 — Refresh).
  Future<void> refresh(BackgroundProfile draft) =>
      _render(draft, status: PreviewStatus.refreshing);

  Future<void> _render(
    BackgroundProfile draft, {
    required PreviewStatus status,
  }) async {
    final sample = draft.calibrationVoiceSamplePath;
    if (sample == null) return;

    final mySeq = ++_renderSeq;
    final usecase = ref.read(generatePreviewUseCaseProvider);

    // Tear down any render still in flight before starting this one.
    await usecase.cancelActive();
    await _player.stop();
    state = state.copyWith(status: status, clearError: true);

    final result = await usecase.call(
      AudioFileRef(
        path: sample,
        name: sample.split('/').last,
        ext: sample.split('.').last.toLowerCase(),
      ),
      draft,
    );

    // A newer render superseded this one (or the controller was disposed) →
    // drop this result so stale output can't overwrite the latest state/clip.
    if (_disposed || mySeq != _renderSeq) return;

    await result.fold(
      (path) async {
        await _player.setFilePath(path);
        if (_disposed || mySeq != _renderSeq) return;
        await _player.seek(Duration.zero);
        _renderedSignature = dspSignature(draft);
        state = state.copyWith(status: PreviewStatus.ready);
      },
      (failure) async {
        // A cancelled render was deliberately superseded — leave the newer
        // render to drive the state rather than flashing an error.
        if (failure is CancelledFailure) return;
        _renderedSignature = null;
        state =
            state.copyWith(status: PreviewStatus.error, error: failure.message);
      },
    );
  }

  /// Toggles play/pause. Restarts from the top only when playback has finished.
  Future<void> togglePlay() async {
    if (!state.hasPreview) return;
    if (_player.playing) {
      await _player.pause();
      state = state.copyWith(status: PreviewStatus.paused);
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
      state = state.copyWith(status: PreviewStatus.playing);
    }
  }

  /// Stops playback and rewinds to the start (design §3 — Stop).
  Future<void> stop() async {
    if (!state.hasPreview) return;
    await _player.pause();
    await _player.seek(Duration.zero);
    state = state.copyWith(status: PreviewStatus.stopped);
  }

  /// Live playback position, for the seek bar's real-time tracking.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Total length of the rendered preview (null until loaded).
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Jumps playback to [position] (driven by the seek bar).
  Future<void> seek(Duration position) => _player.seek(position);

  /// Whether [current]'s settings differ from the loaded preview's, i.e. the
  /// preview no longer reflects the draft and should be regenerated.
  bool isStale(BackgroundProfile current) =>
      _renderedSignature != null &&
      _renderedSignature != dspSignature(current);
}

/// Stable fingerprint of every field that changes the rendered audio. Two drafts
/// with the same signature produce an identical preview, so any difference means
/// the loaded preview is out of date.
String dspSignature(BackgroundProfile p) => [
      p.calibrationVoiceSamplePath,
      p.musicFilePath,
      p.voiceVolume,
      p.musicVolume,
      p.noiseReduction,
      p.voiceEnhancementEnabled,
      p.ducking,
      p.fadeInSeconds,
      p.fadeOutSeconds,
      p.eqBassDb,
      p.eqMidDb,
      p.eqTrebleDb,
      p.normalizationEnabled,
      p.exportFormat,
      p.audioBitrateKbps,
    ].join('|');
