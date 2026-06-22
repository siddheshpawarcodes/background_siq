import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/dataset_batch_progress.dart';
import 'dataset_batch_controller.dart';

/// Dataset Batch Processing — select a root folder, a filename suffix and a
/// profile, then process every matching file recursively, mirroring the source
/// tree under the public `Music/EchoBug/` folder. Independent of the manual
/// batch flow.
class DatasetBatchScreen extends ConsumerStatefulWidget {
  const DatasetBatchScreen({super.key});

  @override
  ConsumerState<DatasetBatchScreen> createState() =>
      _DatasetBatchScreenState();
}

class _DatasetBatchScreenState extends ConsumerState<DatasetBatchScreen> {
  late final TextEditingController _suffixController;

  @override
  void initState() {
    super.initState();
    _suffixController = TextEditingController();
  }

  @override
  void dispose() {
    _suffixController.dispose();
    super.dispose();
  }

  void _addSuffix() {
    final controller = ref.read(datasetBatchControllerProvider.notifier);
    if (controller.addSuffix(_suffixController.text)) {
      _suffixController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(datasetBatchControllerProvider);
    final progress = state.progress;

    final Widget body;
    if (state.running || progress != null) {
      body = (progress != null && progress.completed)
          ? _completionView(progress, state.elapsed)
          : _processingView(progress);
    } else {
      body = _setupView();
    }

    return PopScope(
      canPop: !state.running,
      child: Scaffold(
        appBar: AppBar(title: const Text('Dataset batch processing')),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: body,
        ),
      ),
    );
  }

  // --- Setup view ---
  Widget _setupView() {
    final state = ref.watch(datasetBatchControllerProvider);
    final controller = ref.read(datasetBatchControllerProvider.notifier);
    final profiles =
        ref.watch(profilesProvider).valueOrNull ?? const <BackgroundProfile>[];

    return ListView(
      children: [
        Text('Dataset folder',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Spacing.xs),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(state.rootFolder ?? 'Select dataset folder'),
            subtitle: Text(state.rootFolder == null
                ? 'Choose the root folder to process recursively'
                : 'Tap to change'),
            trailing: const Icon(Icons.folder_open),
            onTap: controller.pickFolder,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text('Suffixes', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Spacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _suffixController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: '_eng',
                  helperText: 'Add one or more; matches "<suffix>.m4a"',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                onSubmitted: (_) => _addSuffix(),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: IconButton.filledTonal(
                onPressed: _addSuffix,
                icon: const Icon(Icons.add),
                tooltip: 'Add suffix',
              ),
            ),
          ],
        ),
        if (state.suffixes.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: [
              for (final s in state.suffixes)
                InputChip(
                  label: Text(s),
                  onDeleted: () => controller.removeSuffix(s),
                ),
            ],
          ),
        ],
        const SizedBox(height: Spacing.lg),
        Text('Profile', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: Spacing.xs),
        DropdownButtonFormField<String>(
          initialValue: state.profileId,
          decoration: const InputDecoration(
            labelText: 'Background music profile',
            prefixIcon: Icon(Icons.tune),
          ),
          items: [
            for (final pr in profiles)
              DropdownMenuItem(value: pr.id, child: Text(pr.name)),
          ],
          onChanged: (id) {
            if (id != null) controller.selectProfile(id);
          },
        ),
        const SizedBox(height: Spacing.lg),
        _outputLocationNote(),
        const SizedBox(height: Spacing.xl),
        FilledButton.icon(
          onPressed: state.canStart ? controller.start : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start processing'),
        ),
      ],
    );
  }

  /// Tells the user where processed files are saved and how the folder layout
  /// is preserved.
  Widget _outputLocationNote() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.save_alt, size: 20, color: scheme.primary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where files are saved',
                      style: textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Processed files go to Music/EchoBug, keeping your original '
                    'folder layout. Each file gets the "_echobug" suffix.',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'e.g. music data/Amalki/Amalki_eng.m4a\n'
                    '→ Music/EchoBug/music data/Amalki/Amalki_eng_echobug.m4a',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Processing view ---
  Widget _processingView(DatasetBatchProgress? pr) {
    final controller = ref.read(datasetBatchControllerProvider.notifier);

    if (pr == null || pr.scanning) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: Spacing.md),
          Center(child: Text('Scanning dataset…')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${(pr.overall * 100).toStringAsFixed(0)}% overall',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        LinearProgressIndicator(value: pr.overall),
        const SizedBox(height: Spacing.lg),
        if (pr.currentFolder != null) ...[
          Text('Current folder',
              style: Theme.of(context).textTheme.labelMedium),
          Text(pr.currentFolder!,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Spacing.sm),
        ],
        if (pr.currentFile != null) ...[
          Text('Current file',
              style: Theme.of(context).textTheme.labelMedium),
          Text(pr.currentFile!, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Spacing.sm),
        ],
        LinearProgressIndicator(
            value: pr.currentFileProgress == 0 ? null : pr.currentFileProgress),
        const SizedBox(height: Spacing.lg),
        Text('${pr.processedFiles} / ${pr.totalFiles}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Spacing.xs),
        _countsRow(pr),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: controller.cancel,
          icon: const Icon(Icons.stop),
          label: const Text('Cancel processing'),
        ),
      ],
    );
  }

  // --- Completion view ---
  Widget _completionView(DatasetBatchProgress pr, Duration? elapsed) {
    final controller = ref.read(datasetBatchControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Icon(pr.cancelled ? Icons.cancel : Icons.task_alt,
                    color: pr.cancelled ? scheme.error : scheme.primary),
                const SizedBox(width: Spacing.md),
                Text(pr.cancelled ? 'Cancelled' : 'Completed',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        _summaryRow('Total files', '${pr.totalFiles}'),
        _summaryRow('Processed', '${pr.processedFiles}'),
        _summaryRow('Successful', '${pr.successfulFiles}'),
        _summaryRow('Failed', '${pr.failedFiles}'),
        _summaryRow('Skipped', '${pr.skippedFiles}'),
        _summaryRow('Duration', _formatDuration(elapsed)),
        if (pr.successfulFiles > 0) ...[
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Icon(Icons.save_alt,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  'Saved to Music/EchoBug, mirroring your folder layout.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        if (pr.failures.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.error_outline, color: scheme.error),
              title: Text('View failed files (${pr.failures.length})'),
              children: [
                for (final f in pr.failures)
                  ListTile(
                    dense: true,
                    title: Text(f.fileName ?? f.filePath,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(f.error,
                        style: TextStyle(color: scheme.error)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            onPressed: controller.retryFailed,
            icon: const Icon(Icons.refresh),
            label: Text('Retry failed files (${pr.failures.length})'),
          ),
        ],
        const SizedBox(height: Spacing.md),
        FilledButton(
          onPressed: controller.reset,
          child: const Text('Process another dataset'),
        ),
      ],
    );
  }

  Widget _countsRow(DatasetBatchProgress pr) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 18, color: scheme.primary),
        const SizedBox(width: Spacing.xs),
        Text('${pr.successfulFiles}'),
        const SizedBox(width: Spacing.md),
        Icon(Icons.error, size: 18, color: scheme.error),
        const SizedBox(width: Spacing.xs),
        Text('${pr.failedFiles}'),
        const SizedBox(width: Spacing.md),
        const Icon(Icons.skip_next, size: 18),
        const SizedBox(width: Spacing.xs),
        Text('${pr.skippedFiles}'),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
