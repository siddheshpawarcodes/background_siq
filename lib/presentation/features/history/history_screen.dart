import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/history_entry.dart';
import '../../router/app_router.dart';
import '../processing/processing_queue_controller.dart';

/// Processing history — source/output, date, profile, duration, status, with
/// "reopen exported file" (SRS §11.5).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          historyAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear history',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmClear(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          const _ProcessingSection(),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load history: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No processing history yet.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _HistoryTile(entry: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all history entries. Exported files are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(historyRepositoryProvider).clear();
  }
}

/// Live "Processing" section pinned above the persisted history. Shows each
/// in-progress / queued background edit with its stage, progress, and a cancel
/// control. Collapses to nothing when the queue is empty; finished edits drop
/// out and reappear below as ordinary history entries.
class _ProcessingSection extends ConsumerWidget {
  const _ProcessingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(processingQueueProvider);
    if (queue.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, Spacing.xs),
            child: Text(
              'Processing (${queue.count})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary),
            ),
          ),
          for (final job in queue.jobs) _QueuedJobTile(job: job),
        ],
      ),
    );
  }
}

class _QueuedJobTile extends ConsumerWidget {
  const _QueuedJobTile({required this.job});

  final QueuedJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = job.isRunning;
    final subtitle = running ? job.stage.label : 'Queued';
    return ListTile(
      dense: true,
      leading: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: running && job.progress > 0 ? job.progress : null,
        ),
      ),
      title: Text(job.source.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        running ? '$subtitle · ${(job.progress * 100).round()}%' : subtitle,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancel',
        onPressed: () => ref.read(processingQueueProvider.notifier).cancel(job.id),
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final success = entry.status == JobStatus.success;
    return ListTile(
      leading: Icon(
        success ? Icons.check_circle_outline : Icons.error_outline,
        color: success ? scheme.primary : scheme.error,
      ),
      title: Text(p.basename(entry.outputPath), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${entry.profileName} · ${_date(entry.date)} · '
        '${entry.processingTime.inSeconds}s',
      ),
      trailing: success
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  tooltip: 'Play in app',
                  onPressed: () => _openPlayer(context),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open externally',
                  onPressed: () => _open(context, ref),
                ),
              ],
            )
          : null,
      onTap: success ? () => _openPlayer(context) : null,
    );
  }

  /// Opens the in-app music player starting on this finished file.
  void _openPlayer(BuildContext context) {
    context.push(Routes.player, extra: entry.id);
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(openFileServiceProvider).open(entry.outputPath);
    if (context.mounted && result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file. It may have been moved.')),
      );
    }
  }

  String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
