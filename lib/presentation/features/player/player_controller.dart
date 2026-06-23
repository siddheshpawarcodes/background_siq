import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/di/repository_providers.dart';
import '../../../domain/entities/enums.dart';
import 'player_track.dart';

/// Live view of the player for the UI. Position/duration are intentionally
/// excluded here — those tick many times a second and are fed straight to the
/// [AudioSeekBar] via streams to avoid rebuilding the whole screen.
class PlayerState {
  const PlayerState({
    this.queue = const [],
    this.currentIndex,
    this.playing = false,
    this.loading = false,
    this.error,
  });

  final List<PlayerTrack> queue;
  final int? currentIndex;
  final bool playing;
  final bool loading;
  final String? error;

  PlayerTrack? get current {
    final i = currentIndex;
    if (i == null || i < 0 || i >= queue.length) return null;
    return queue[i];
  }

  /// Tracks that will play after the current one — the "Up next" list.
  List<PlayerTrack> get upNext {
    final i = currentIndex;
    if (i == null || i + 1 >= queue.length) return const [];
    return queue.sublist(i + 1);
  }

  PlayerState copyWith({
    List<PlayerTrack>? queue,
    int? currentIndex,
    bool? playing,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        currentIndex: currentIndex ?? this.currentIndex,
        playing: playing ?? this.playing,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// The finished files the player can browse and play: successful history
/// entries whose output still exists on disk, newest first (the order
/// [historyProvider] already guarantees). This is both the "Recents" list and
/// the playable queue.
final playableTracksProvider = Provider<List<PlayerTrack>>((ref) {
  final history = ref.watch(historyProvider).valueOrNull ?? const [];
  return [
    for (final e in history)
      if (e.status == JobStatus.success) PlayerTrack.fromHistory(e),
  ];
});

/// A single app-wide audio player. Not auto-disposed: playback survives leaving
/// the player screen (so a future mini-player can re-attach), and is torn down
/// only when the app's [ProviderScope] is.
final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

/// Owns the one [AudioPlayer] and its queue. Built on just_audio's playlist
/// ([ConcatenatingAudioSource]) so next/previous and auto-advance are handled
/// natively; the UI is derived from [currentIndexStream] + [playerStateStream].
class PlayerController extends Notifier<PlayerState> {
  late final AudioPlayer _player;

  @override
  PlayerState build() {
    _player = AudioPlayer();
    final indexSub = _player.currentIndexStream.listen((i) {
      state = state.copyWith(currentIndex: i);
    });
    final stateSub = _player.playerStateStream.listen((s) {
      state = state.copyWith(playing: s.playing);
    });
    ref.onDispose(() {
      indexSub.cancel();
      stateSub.cancel();
      _player.dispose();
    });
    return const PlayerState();
  }

  /// Live playback position, for the seek bar's real-time tracking.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Total length of the current track (null until loaded).
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Opens [tracks] and starts playing at [startIndex]. If the same queue is
  /// already loaded, jumps to the requested track (or resumes) instead of
  /// rebuilding the playlist — so re-opening the screen never restarts audio.
  Future<void> openFrom(List<PlayerTrack> tracks, int startIndex) async {
    final unchanged = _samePaths(state.queue, tracks) && _player.audioSource != null;
    if (unchanged) {
      if (state.currentIndex != startIndex) {
        await playAt(startIndex);
      } else if (!_player.playing) {
        await _player.play();
      }
      return;
    }
    await _loadQueue(tracks, startIndex);
  }

  Future<void> _loadQueue(List<PlayerTrack> tracks, int startIndex) async {
    state = state.copyWith(queue: tracks, loading: true, clearError: true);
    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(
          children: [
            for (final t in tracks) AudioSource.uri(Uri.file(t.path)),
          ],
        ),
        initialIndex: startIndex,
      );
      state = state.copyWith(loading: false, currentIndex: startIndex);
      await _player.play();
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Could not play this file — it may have been moved or deleted.',
      );
    }
  }

  /// Plays the queue item at [index] from the start.
  Future<void> playAt(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  /// Play/pause toggle. Restarts from the top only if playback had finished.
  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> next() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  /// Restarts the current track if it's already a few seconds in (or there's no
  /// earlier track), otherwise jumps to the previous one — the usual behaviour.
  Future<void> previous() async {
    if (_player.position > const Duration(seconds: 5) || !_player.hasPrevious) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  /// Halts playback and rewinds to the start of the current track (resumable).
  Future<void> stop() async {
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  bool _samePaths(List<PlayerTrack> a, List<PlayerTrack> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path) return false;
    }
    return true;
  }
}
