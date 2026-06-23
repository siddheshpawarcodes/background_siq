import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/background_profile.dart';
import '../../router/app_router.dart';

/// Profiles list — add / edit / duplicate / delete (SRS §11.3).
class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backdrops'),
        actions: [
          IconButton(
            tooltip: 'Import backdrop',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _import(context, ref),
          ),
        ],
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load backdrops: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No backdrops yet. Tap + to create one.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            itemCount: profiles.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _ProfileTile(profile: profiles[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.profileEdit),
        icon: const Icon(Icons.add),
        label: const Text('New Backdrop'),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(importProfileUseCaseProvider).call();
    if (!context.mounted) return;
    result.fold(
      (profile) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profile == null ? 'Import cancelled' : 'Imported "${profile.name}"',
          ),
        ),
      ),
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.profile});

  final BackgroundProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMusic = profile.musicFilePath != null;
    return ListTile(
      leading: CircleAvatar(child: Text(profile.name.characters.first.toUpperCase())),
      title: Text(profile.name),
      subtitle: Text(
        '${profile.exportFormat.label} · Music ${profile.musicVolume}%'
        '${hasMusic ? '' : ' · no track set'}',
      ),
      onTap: () => context.push('${Routes.profileEdit}/${profile.id}'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _onAction(context, ref, value),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit / Calibrate')),
          PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
          PopupMenuItem(value: 'export', child: Text('Export')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        context.push('${Routes.profileEdit}/${profile.id}');
      case 'duplicate':
        await ref.read(duplicateProfileUseCaseProvider).call(profile.id);
      case 'export':
        await ref.read(exportProfileUseCaseProvider).call(profile);
      case 'delete':
        final confirmed = await _confirmDelete(context);
        if (confirmed ?? false) {
          await ref.read(deleteProfileUseCaseProvider).call(profile.id);
        }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete backdrop?'),
          content: Text('"${profile.name}" will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
}
