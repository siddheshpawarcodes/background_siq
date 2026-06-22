import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/background_profile.dart';

/// State of the calibration live-preview (design §7).
class PreviewState {
  const PreviewState({
    this.generating = false,
    this.playing = false,
    this.hasPreview = false,
    this.error,
  });

  final bool generating;
  final bool playing;
  final bool hasPreview;
  final String? error;

  PreviewState copyWith({
    bool? generating,
    bool? playing,
    bool? hasPreview,
    String? error,
    bool clearError = false,
  }) =>
      PreviewState(
        generating: generating ?? this.generating,
        playing: playing ?? this.playing,
        hasPreview: hasPreview ?? this.hasPreview,
        error: clearError ? null : (error ?? this.error),
      );
}

final calibrationPreviewControllerProvider =
    NotifierProvider.autoDispose<CalibrationPreviewController, PreviewState>(
  CalibrationPreviewController.new,
);

/// Renders a 15 s preview of the draft profile against the calibration sample
/// and plays it. Cancels any prior render before starting a new one so rapid
/// iteration never piles up native sessions (design §7, edge E3).
class CalibrationPreviewController extends AutoDisposeNotifier<PreviewState> {
  late final AudioPlayer _player;

  @override
  PreviewState build() {
    _player = AudioPlayer();
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        state = state.copyWith(playing: false);
      }
    });
    ref.onDispose(() {
      ref.read(generatePreviewUseCaseProvider).cancelActive();
      _player.dispose();
    });
    return const PreviewState();
  }

  /// Renders + plays a preview for [sample] using [draft].
  Future<void> preview(AudioFileRef sample, BackgroundProfile draft) async {
    await ref.read(generatePreviewUseCaseProvider).cancelActive();
    await _player.stop();
    state = state.copyWith(generating: true, clearError: true);

    final result =
        await ref.read(generatePreviewUseCaseProvider).call(sample, draft);

    await result.fold(
      (path) async {
        await _player.setFilePath(path);
        await _player.play();
        state = state.copyWith(generating: false, playing: true, hasPreview: true);
      },
      (failure) async {
        state = state.copyWith(generating: false, error: failure.message);
      },
    );
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
      state = state.copyWith(playing: false);
    } else {
      // Restart from the top only when playback has already finished; otherwise
      // resume from the current seek position.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
      state = state.copyWith(playing: true);
    }
  }

  /// Live playback position, for the seek bar's real-time tracking.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Total length of the rendered preview (null until loaded).
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Jumps playback to [position] (driven by the seek bar).
  Future<void> seek(Duration position) => _player.seek(position);
}
