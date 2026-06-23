import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../features/processing/processing_queue_controller.dart';
import '../router/app_router.dart';

/// Slim, app-wide strip shown above every tab while background edits are
/// running. Tapping it jumps to History, where each job's detailed progress
/// lives. Collapses to nothing when the queue is empty.
class ProcessingBanner extends ConsumerWidget {
  const ProcessingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(processingQueueProvider);
    if (queue.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final running = queue.running;
    final label = running == null
        ? 'Queued ${queue.count} edit${queue.count == 1 ? '' : 's'}'
        : '${running.source.name} · ${running.stage.label}';

    return Material(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: () => context.go(Routes.history),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: running == null || running.progress == 0
                      ? null
                      : running.progress,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  queue.count > 1 ? '$label  (+${queue.count - 1} more)' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
