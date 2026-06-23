import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/background_profile.dart';
import '../../router/app_router.dart';
import '../../shared/audio_seek_bar.dart';
import '../processing/processing_screen.dart';
import 'home_controller.dart';

/// Main screen — file selector, profile dropdown, Preview, Apply (SRS §11.1).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _player = AudioPlayer();
  bool _previewBusy = false;
  bool _hasPreview = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeControllerProvider);
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Batch processing',
            icon: const Icon(Icons.library_add_outlined),
            onPressed: () => context.push(Routes.batch),
          ),
          IconButton(
            tooltip: 'Dataset batch processing',
            icon: const Icon(Icons.folder_special_outlined),
            onPressed: () => context.push(Routes.datasetBatch),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _fileSelector(home),
          const SizedBox(height: Spacing.md),
          profilesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load profiles: $e'),
            data: (profiles) => _profileDropdown(profiles, home.profileId),
          ),
          const SizedBox(height: Spacing.xl),
          _actions(home, profilesAsync.valueOrNull ?? const []),
          if (_hasPreview) ...[
            const SizedBox(height: Spacing.md),
            _previewPlayer(),
          ],
          const SizedBox(height: Spacing.xl),
          _recents(),
        ],
      ),
    );
  }

  Widget _fileSelector(HomeState home) {
    final file = home.file;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.audio_file_outlined),
        title: Text(file?.name ?? 'No file selected'),
        subtitle: Text(file == null ? 'Tap to choose a recording' : file.ext.toUpperCase()),
        trailing: const Icon(Icons.folder_open),
        onTap: () => ref.read(homeControllerProvider.notifier).pickFile(),
      ),
    );
  }

  Widget _profileDropdown(List<BackgroundProfile> profiles, String? selectedId) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'Background music profile',
        prefixIcon: Icon(Icons.tune),
      ),
      items: [
        for (final pr in profiles)
          DropdownMenuItem(value: pr.id, child: Text(pr.name)),
      ],
      onChanged: (id) {
        if (id != null) ref.read(homeControllerProvider.notifier).selectProfile(id);
      },
    );
  }

  Widget _actions(HomeState home, List<BackgroundProfile> profiles) {
    BackgroundProfile? selected() {
      for (final pr in profiles) {
        if (pr.id == home.profileId) return pr;
      }
      return null;
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: home.canApply && !_previewBusy
                ? () => _preview(home, selected())
                : null,
            icon: _previewBusy
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: const Text('Preview'),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: home.canApply ? () => _apply(home, selected()) : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Apply'),
          ),
        ),
      ],
    );
  }

  Future<void> _preview(HomeState home, BackgroundProfile? profile) async {
    if (home.file == null || profile == null) return;
    setState(() => _previewBusy = true);
    final result =
        await ref.read(generatePreviewUseCaseProvider).call(home.file!, profile);
    if (!mounted) return;
    setState(() => _previewBusy = false);
    await result.fold(
      (path) async {
        await _player.setFilePath(path);
        await _player.play();
        if (mounted) setState(() => _hasPreview = true);
      },
      (failure) async => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  /// Player shown once a preview has rendered: a play/pause toggle plus a
  /// scrub bar so the user can audition the whole result back and forth.
  Widget _previewPlayer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                return Row(
                  children: [
                    IconButton(
                      iconSize: 40,
                      onPressed: _togglePreviewPlay,
                      icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text('Preview',
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                );
              },
            ),
            AudioSeekBar(
              positionStream: _player.positionStream,
              durationStream: _player.durationStream,
              onSeek: (position) => _player.seek(position),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePreviewPlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      // Restart from the top only when playback has finished; otherwise resume.
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  void _apply(HomeState home, BackgroundProfile? profile) {
    if (home.file == null || profile == null) return;
    context.push(
      Routes.processing,
      extra: ApplyArgs(source: home.file!, profile: profile),
    );
  }

  Widget _recents() {
    final recentsAsync = ref.watch(recentFilesProvider);
    final recents = recentsAsync.valueOrNull ?? const [];
    if (recents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent files', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Spacing.sm),
        for (final f in recents.take(5))
          ListTile(
            dense: true,
            leading: const Icon(Icons.history),
            title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => ref.read(homeControllerProvider.notifier).selectFileRef(f),
          ),
      ],
    );
  }
}
