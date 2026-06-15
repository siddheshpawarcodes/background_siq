import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/history_entry.dart';

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
      body: historyAsync.when(
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
          ? IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open file',
              onPressed: () => _open(context, ref),
            )
          : null,
      onTap: success ? () => _open(context, ref) : null,
    );
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
