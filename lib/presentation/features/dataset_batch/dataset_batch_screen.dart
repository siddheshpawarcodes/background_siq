import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/dataset_batch_progress.dart';
import '../../shared/cover_image_card.dart';
import '../../shared/navigation/nav_log.dart';
import '../../shared/navigation/navigation_dialogs.dart';
import '../../shared/navigation/navigation_guard.dart';
import '../../shared/navigation/processing_status.dart';
import 'dataset_batch_controller.dart';
import 'dataset_batch_state.dart';

/// Dataset Batch Processing — select a root folder, then pair each filename
/// suffix with its own profile (background music), and process every matching
/// file recursively, mirroring the source tree under the public `Music/EchoBug/`
/// folder. Each suffix can get a different background music in one run.
/// Independent of the manual batch flow.
class DatasetBatchScreen extends ConsumerStatefulWidget {
  const DatasetBatchScreen({super.key});

  @override
  ConsumerState<DatasetBatchScreen> createState() =>
      _DatasetBatchScreenState();
}

class _DatasetBatchScreenState extends ConsumerState<DatasetBatchScreen> {
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

    return NavigationGuard(
      debugLabel: 'dataset-batch',
      // Pop freely only when nothing is running and no setup has been entered.
      canPop: !state.running && !state.hasSetupInput,
      onConfirmLeave: _confirmLeave,
      child: Scaffold(
        appBar: AppBar(title: const Text('Dataset batch processing')),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: body,
        ),
      ),
    );
  }

  /// Starts a run unless another processing engine already owns the foreground
  /// service (Processing-Aware Navigation).
  void _startGuarded() {
    if (otherEngineActive(ref, excluding: ProcessingEngine.dataset)) {
      showAlreadyRunningMessage(context);
      return;
    }
    ref.read(datasetBatchControllerProvider.notifier).start();
  }

  /// Back-press policy: while running offer background/cancel/stay; otherwise
  /// warn before discarding unsaved setup.
  Future<bool> _confirmLeave() async {
    final state = ref.read(datasetBatchControllerProvider);
    final controller = ref.read(datasetBatchControllerProvider.notifier);
    if (state.running) {
      final action = await showProcessingRunningDialog(
        context,
        canBackground: true,
        title: 'Dataset Processing Running',
      );
      switch (action) {
        case LeaveAction.background:
          // Foreground service keeps the run alive; just leave.
          NavLog.event(NavEvent.processingScreenExited, 'dataset/background');
          return true;
        case LeaveAction.cancel:
          // Cancel gracefully and stay to show cancellation progress.
          controller.cancel();
          return false;
        case LeaveAction.stay:
          return false;
      }
    }
    if (state.hasSetupInput) {
      if (!mounted) return false;
      final leave = await confirmLeaveSetup(context);
      if (leave) controller.reset();
      return leave;
    }
    return true;
  }

  // --- Setup view ---
  Widget _setupView() {
    final state = ref.watch(datasetBatchControllerProvider);
    final controller = ref.read(datasetBatchControllerProvider.notifier);
    final profiles =
        ref.watch(profilesProvider).valueOrNull ?? const <BackgroundProfile>[];
    final duplicates = state.duplicateSuffixes;

    return ListView(
      children: [
        Text('Dataset folder',
            style: Theme.of(context).textTheme.titleSmall),
        Spacing.xs.verticalSpace,
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
        Spacing.lg.verticalSpace,
        Text('Suffixes & background music',
            style: Theme.of(context).textTheme.titleSmall),
        Spacing.xs.verticalSpace,
        Text(
          'Pair each filename suffix (e.g. "_eng") with the backdrop to apply to '
          'matching files. Files for different suffixes get different music.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Spacing.sm.verticalSpace,
        if (state.entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                'No suffixes yet. Add one to map it to a backdrop.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          for (final entry in state.entries)
            Padding(
              key: ValueKey('suffix_row_${entry.id}'),
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _SuffixProfileRow(
                entry: entry,
                profiles: profiles,
                isDuplicate: entry.suffix.trim().isNotEmpty &&
                    duplicates.contains(entry.suffix.trim()),
                onSuffixChanged: (v) => controller.setEntrySuffix(entry.id, v),
                onProfileChanged: (v) =>
                    controller.setEntryProfile(entry.id, v),
                onRemove: () => controller.removeEntry(entry.id),
                onPickCover: () => controller.pickEntryCover(entry.id),
                onClearCover: () => controller.setEntryCover(entry.id, null),
              ),
            ),
        Spacing.xs.verticalSpace,
        OutlinedButton.icon(
          onPressed: controller.addEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add suffix'),
        ),
        if (duplicates.isNotEmpty) ...[
          Spacing.sm.verticalSpace,
          _hint(
            'Duplicate suffix: ${duplicates.join(', ')}. Each suffix must be '
            'unique.',
            isError: true,
          ),
        ],
        Spacing.lg.verticalSpace,
        _outputLocationNote(),
        Spacing.xl.verticalSpace,
        FilledButton.icon(
          onPressed: state.canStart ? _startGuarded : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start processing'),
        ),
      ],
    );
  }

  Widget _hint(String text, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isError ? Icons.error_outline : Icons.info_outline,
            size: 16, color: isError ? scheme.error : scheme.onSurfaceVariant),
        Spacing.xs.horizontalSpace,
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isError ? scheme.error : scheme.onSurfaceVariant,
                ),
          ),
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
            Spacing.sm.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where files are saved',
                      style: textTheme.labelLarge),
                  Spacing.xs.verticalSpace,
                  Text(
                    'Processed files go to Music/EchoBug, keeping your original '
                    'folder layout. Each file gets the "_echobug" suffix.',
                    style: textTheme.bodySmall,
                  ),
                  Spacing.xs.verticalSpace,
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
      final discovered = pr?.scanDiscovered ?? 0;
      final matched = pr?.scanMatched ?? 0;
      return Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                Spacing.md.verticalSpace,
                const Text('Scanning dataset…'),
                if (discovered > 0 || matched > 0) ...[
                  Spacing.sm.verticalSpace,
                  Text('$discovered found · $matched matched',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (pr?.currentFolder != null) ...[
                  Spacing.xs.verticalSpace,
                  Text('in ${pr!.currentFolder!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (kDebugMode) _diagnosticsPanel(pr),
          Spacing.md.verticalSpace,
          OutlinedButton.icon(
            onPressed: controller.cancel,
            icon: const Icon(Icons.stop),
            label: const Text('Cancel'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${(pr.overall * 100).toStringAsFixed(0)}% overall',
            style: Theme.of(context).textTheme.headlineSmall),
        Spacing.sm.verticalSpace,
        LinearProgressIndicator(value: pr.overall),
        Spacing.lg.verticalSpace,
        if (pr.currentFolder != null) ...[
          Text('Current folder',
              style: Theme.of(context).textTheme.labelMedium),
          Text(pr.currentFolder!,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Spacing.sm.verticalSpace,
        ],
        if (pr.currentFile != null) ...[
          Text('Current file',
              style: Theme.of(context).textTheme.labelMedium),
          Text(pr.currentFile!, maxLines: 1, overflow: TextOverflow.ellipsis),
          Spacing.sm.verticalSpace,
        ],
        LinearProgressIndicator(
            value: pr.currentFileProgress == 0 ? null : pr.currentFileProgress),
        Spacing.lg.verticalSpace,
        Text('${pr.processedFiles} / ${pr.totalFiles}',
            style: Theme.of(context).textTheme.titleMedium),
        Spacing.xs.verticalSpace,
        _countsRow(pr),
        const Spacer(),
        if (kDebugMode) ...[
          _diagnosticsPanel(pr),
          Spacing.md.verticalSpace,
        ],
        OutlinedButton.icon(
          onPressed: controller.cancel,
          icon: const Icon(Icons.stop),
          label: const Text('Cancel processing'),
        ),
      ],
    );
  }

  /// Debug-only panel that surfaces the raw pipeline state so a stall is never
  /// invisible: which phase is live, scan counts, current folder/file/stage and
  /// the most recent error. Shown only in debug builds ([kDebugMode]).
  Widget _diagnosticsPanel(DatasetBatchProgress? pr) {
    final scheme = Theme.of(context).colorScheme;
    final phase = pr == null
        ? 'starting'
        : pr.completed
            ? 'completed'
            : pr.scanning
                ? 'scanning'
                : 'processing';
    final lastError = pr?.failures.isNotEmpty == true
        ? '${pr!.failures.last.fileName ?? pr.failures.last.filePath}: '
            '${pr.failures.last.error}'
        : '—';
    final rows = <(String, String)>[
      ('phase', phase),
      ('scanning', '${pr?.scanning ?? false}'),
      ('found / matched', '${pr?.scanDiscovered ?? 0} / ${pr?.scanMatched ?? 0}'),
      ('processed / total', '${pr?.processedFiles ?? 0} / ${pr?.totalFiles ?? 0}'),
      ('ok / fail / skip',
          '${pr?.successfulFiles ?? 0} / ${pr?.failedFiles ?? 0} / ${pr?.skippedFiles ?? 0}'),
      ('current folder', pr?.currentFolder ?? '—'),
      ('current file', pr?.currentFile ?? '—'),
      ('current stage', pr?.currentStage ?? '—'),
      ('last error', lastError),
    ];
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, size: 16, color: scheme.primary),
                Spacing.xs.horizontalSpace,
                Text('Diagnostics (debug)',
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            Spacing.xs.verticalSpace,
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(label,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Text(value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontFeatures: const [])),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
                Spacing.md.horizontalSpace,
                Text(pr.cancelled ? 'Cancelled' : 'Completed',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
        if (pr.noMatchReason != null) ...[
          Spacing.md.verticalSpace,
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.onErrorContainer),
                  Spacing.sm.horizontalSpace,
                  Expanded(
                    child: Text(
                      pr.noMatchReason!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Spacing.md.verticalSpace,
        _summaryRow('Total files', '${pr.totalFiles}'),
        _summaryRow('Processed', '${pr.processedFiles}'),
        _summaryRow('Successful', '${pr.successfulFiles}'),
        _summaryRow('Failed', '${pr.failedFiles}'),
        _summaryRow('Skipped', '${pr.skippedFiles}'),
        _summaryRow('Duration', _formatDuration(elapsed)),
        if (pr.successfulFiles > 0) ...[
          Spacing.sm.verticalSpace,
          Row(
            children: [
              Icon(Icons.save_alt,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              Spacing.xs.horizontalSpace,
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
          Spacing.md.verticalSpace,
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
          Spacing.md.verticalSpace,
          OutlinedButton.icon(
            onPressed: controller.retryFailed,
            icon: const Icon(Icons.refresh),
            label: Text('Retry failed files (${pr.failures.length})'),
          ),
        ],
        Spacing.md.verticalSpace,
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
        Spacing.xs.horizontalSpace,
        Text('${pr.successfulFiles}'),
        Spacing.md.horizontalSpace,
        Icon(Icons.error, size: 18, color: scheme.error),
        Spacing.xs.horizontalSpace,
        Text('${pr.failedFiles}'),
        Spacing.md.horizontalSpace,
        const Icon(Icons.skip_next, size: 18),
        Spacing.xs.horizontalSpace,
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

/// One editable suffix→profile row: a suffix text field, a profile dropdown,
/// and a remove button. Owns its own [TextEditingController] keyed by the
/// entry's stable id so typing survives parent rebuilds without cursor jumps.
class _SuffixProfileRow extends StatefulWidget {
  const _SuffixProfileRow({
    required this.entry,
    required this.profiles,
    required this.isDuplicate,
    required this.onSuffixChanged,
    required this.onProfileChanged,
    required this.onRemove,
    required this.onPickCover,
    required this.onClearCover,
  });

  final SuffixProfileEntry entry;
  final List<BackgroundProfile> profiles;
  final bool isDuplicate;
  final ValueChanged<String> onSuffixChanged;
  final ValueChanged<String> onProfileChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickCover;
  final VoidCallback onClearCover;

  @override
  State<_SuffixProfileRow> createState() => _SuffixProfileRowState();
}

class _SuffixProfileRowState extends State<_SuffixProfileRow> {
  late final TextEditingController _suffixController;

  @override
  void initState() {
    super.initState();
    _suffixController = TextEditingController(text: widget.entry.suffix);
  }

  @override
  void didUpdateWidget(_SuffixProfileRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync only on an external change (e.g. reset), never while the user types
    // (the field already drives the state, so text == entry.suffix then).
    if (widget.entry.suffix != _suffixController.text) {
      _suffixController.text = widget.entry.suffix;
    }
  }

  @override
  void dispose() {
    _suffixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A profile id that no longer exists (e.g. deleted) must not be passed as
    // the dropdown value or it throws; fall back to no selection.
    final ids = widget.profiles.map((p) => p.id).toSet();
    final selected = ids.contains(widget.entry.profileId)
        ? widget.entry.profileId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _suffixController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '_eng',
                  isDense: true,
                  prefixIcon: const Icon(Icons.text_fields),
                  errorText: widget.isDuplicate ? 'Duplicate' : null,
                ),
                onChanged: widget.onSuffixChanged,
              ),
            ),
            Spacing.sm.horizontalSpace,
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Backdrop',
                  isDense: true,
                  prefixIcon: Icon(Icons.tune),
                ),
                items: [
                  for (final pr in widget.profiles)
                    DropdownMenuItem(
                      value: pr.id,
                      child: Text(pr.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) widget.onProfileChanged(id);
                },
              ),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close),
              tooltip: 'Remove suffix',
            ),
          ],
        ),
        Spacing.xs.verticalSpace,
        CoverImageCard(
          path: widget.entry.coverImagePath,
          onPick: widget.onPickCover,
          onClear: widget.onClearCover,
        ),
      ],
    );
  }
}
