import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/audio_seek_bar.dart';
import 'player_controller.dart';
import 'player_track.dart';

/// Full-screen, YouTube-Music-style player for previewing finished audio.
///
/// Always rendered dark/immersive regardless of the app theme. Opens at
/// [initialTrackId] (a [HistoryEntry] id) and feeds the whole finished-files
/// list to one app-wide [PlayerController] as the playable queue.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, this.initialTrackId});

  /// History entry id to start on; falls back to the newest file when null.
  final String? initialTrackId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Load the queue after the first frame so providers are settled.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final tracks = ref.read(playableTracksProvider);
    if (tracks.isEmpty) return;
    var index = 0;
    final id = widget.initialTrackId;
    if (id != null) {
      final found = tracks.indexWhere((t) => t.id == id);
      if (found >= 0) index = found;
    }
    ref.read(playerControllerProvider.notifier).openFrom(tracks, index);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTheme.brandSeed,
      brightness: Brightness.dark,
    );
    final state = ref.watch(playerControllerProvider);
    final tracks = ref.watch(playableTracksProvider);

    return Theme(
      data: ThemeData(useMaterial3: true, colorScheme: scheme),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primaryContainer, scheme.surface, Colors.black],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: SafeArea(
            child: _body(context, state, tracks),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PlayerState state, List<PlayerTrack> tracks) {
    if (tracks.isEmpty && state.queue.isEmpty) {
      return _empty(context);
    }
    return Column(
      children: [
        _topBar(context),
        Expanded(flex: 5, child: _nowPlaying(context, state)),
        Expanded(flex: 4, child: _tabs(context, state, tracks)),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Stack(
      children: [
        Align(alignment: Alignment.topLeft, child: _collapseButton(context)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.library_music_outlined, size: 64, color: Colors.white54),
                Spacing.md.verticalSpace,
                Text(
                  'No finished files yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                Spacing.xs.verticalSpace,
                const Text(
                  'Process a recording from the Home screen and it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _collapseButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
        tooltip: 'Close',
        onPressed: () => context.pop(),
      );

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: Row(
        children: [
          _collapseButton(context),
          const Expanded(
            child: Text(
              'NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          48.horizontalSpace, // balances the leading icon
        ],
      ),
    );
  }

  Widget _nowPlaying(BuildContext context, PlayerState state) {
    final track = state.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          Expanded(child: Center(child: _artwork())),
          Spacing.lg.verticalSpace,
          _titleBlock(context, track, state.loading),
          Spacing.sm.verticalSpace,
          AudioSeekBar(
            positionStream: ref.read(playerControllerProvider.notifier).positionStream,
            durationStream: ref.read(playerControllerProvider.notifier).durationStream,
            onSeek: (pos) => ref.read(playerControllerProvider.notifier).seek(pos),
          ),
          Spacing.xs.verticalSpace,
          _controls(context, state),
          Spacing.md.verticalSpace,
        ],
      ),
    );
  }

  Widget _artwork() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A4A6B), Color(0xFF1B2233)],
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.music_note, size: 96, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _titleBlock(BuildContext context, PlayerTrack? track, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            track?.title ?? (loading ? 'Loading…' : 'Nothing playing'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        Spacing.xs.verticalSpace,
        Text(
          track?.subtitle ?? ' ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60),
        ),
      ],
    );
  }

  Widget _controls(BuildContext context, PlayerState state) {
    final controller = ref.read(playerControllerProvider.notifier);
    final hasTrack = state.current != null;
    final index = state.currentIndex;
    final canNext = index != null && index < state.queue.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconButton(
          icon: Icons.skip_previous,
          size: 40,
          onPressed: hasTrack ? controller.previous : null,
        ),
        _playPauseButton(state.playing, hasTrack ? controller.togglePlay : null),
        _iconButton(
          icon: Icons.skip_next,
          size: 40,
          onPressed: canNext ? controller.next : null,
        ),
        _iconButton(
          icon: Icons.stop,
          size: 32,
          onPressed: hasTrack ? controller.stop : null,
        ),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required double size, VoidCallback? onPressed}) {
    return IconButton(
      iconSize: size,
      color: Colors.white,
      disabledColor: Colors.white24,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  Widget _playPauseButton(bool playing, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed == null ? Colors.white24 : Colors.white,
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          size: 40,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _tabs(BuildContext context, PlayerState state, List<PlayerTrack> tracks) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: scheme.primary,
            tabs: const [
              Tab(text: 'Up next'),
              Tab(text: 'Recents'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _upNextList(state),
                _recentsList(state, tracks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upNextList(PlayerState state) {
    final upNext = state.upNext;
    if (upNext.isEmpty) {
      return _listPlaceholder('Nothing up next');
    }
    final controller = ref.read(playerControllerProvider.notifier);
    final base = (state.currentIndex ?? -1) + 1;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: upNext.length,
      itemBuilder: (context, i) => _trackTile(
        track: upNext[i],
        isCurrent: false,
        onTap: () => controller.playAt(base + i),
      ),
    );
  }

  Widget _recentsList(PlayerState state, List<PlayerTrack> tracks) {
    if (tracks.isEmpty) {
      return _listPlaceholder('No finished files yet');
    }
    final controller = ref.read(playerControllerProvider.notifier);
    final currentId = state.current?.id;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: tracks.length,
      itemBuilder: (context, i) => _trackTile(
        track: tracks[i],
        isCurrent: tracks[i].id == currentId,
        // Re-open from the live list so newly-finished files join the queue.
        onTap: () => controller.openFrom(tracks, i),
      ),
    );
  }

  Widget _trackTile({
    required PlayerTrack track,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        isCurrent ? Icons.equalizer : Icons.music_note_outlined,
        color: isCurrent ? accent : Colors.white54,
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isCurrent ? accent : Colors.white),
      ),
      subtitle: Text(
        track.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: isCurrent
          ? Icon(Icons.volume_up, size: 18, color: accent)
          : null,
    );
  }

  Widget _listPlaceholder(String text) => Center(
        child: Text(text, style: const TextStyle(color: Colors.white54)),
      );
}
