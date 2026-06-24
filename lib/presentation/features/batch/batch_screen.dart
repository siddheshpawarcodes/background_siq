import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/batch_progress.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/enums.dart';
import '../../shared/cover_image_card.dart';
import '../../shared/navigation/navigation_dialogs.dart';
import '../../shared/navigation/navigation_guard.dart';
import '../../shared/navigation/processing_status.dart';

/// Batch mode — add up to 50 files, pick one profile, process them all
/// sequentially (SRS §15).
class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> {
  final List<AudioFileRef> _files = [];
  String? _profileId;
  bool _running = false;
  BatchProgress? _progress;
  StreamSubscription<BatchProgress>? _sub;

  /// Optional cover-art image (thumbnail) embedded in every file of this batch.
  /// Chosen here, alongside the backdrop, rather than baked into the backdrop.
  String? _thumbnailPath;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _addFiles() async {
    final paths = await ref.read(filePickServiceProvider).pickAudioPaths();
    if (paths.isEmpty) return;
    final existing = _files.map((f) => f.path).toSet();
    final added = <AudioFileRef>[];
    for (final path in paths) {
      if (existing.contains(path)) continue;
      added.add(AudioFileRef(
        path: path,
        name: p.basename(path),
        ext: p.extension(path).replaceFirst('.', '').toLowerCase(),
      ));
    }
    setState(() {
      final room = AppConstants.maxBatchFiles - _files.length;
      _files.addAll(added.take(room));
    });
    if (added.length > AppConstants.maxBatchFiles - (_files.length - added.length) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limited to ${AppConstants.maxBatchFiles} files per batch.')),
      );
    }
  }

  Future<void> _pickThumbnail() async {
    final path = await ref.read(filePickServiceProvider).pickImagePath();
    if (path != null) setState(() => _thumbnailPath = path);
  }

  /// Back-press policy. Manual batch runs screen-locally (not backgrounded), so
  /// while running we offer only Cancel / Stay; otherwise warn before
  /// discarding unsaved setup.
  Future<bool> _confirmLeave() async {
    if (_running) {
      final action = await showProcessingRunningDialog(context, canBackground: false);
      switch (action) {
        case LeaveAction.cancel:
          await _sub?.cancel();
          return true;
        case LeaveAction.background:
        case LeaveAction.stay:
          return false;
      }
    }
    if (!mounted) return false;
    return confirmLeaveSetup(
      context,
      title: 'Leave Batch Setup?',
      message: 'You have unsaved batch configuration.',
    );
  }

  void _start(BackgroundProfile profile) {
    // One active engine at a time — don't overlap with a backgrounded job.
    if (anyEngineActive(ref)) {
      showAlreadyRunningMessage(context);
      return;
    }
    setState(() {
      _running = true;
      _progress = null;
    });
    final stream = ref.read(processBatchUseCaseProvider).call(
          List.of(_files),
          profile.copyWith(coverImagePath: _thumbnailPath),
        );
    _sub = stream.listen(
      (progress) => setState(() => _progress = progress),
      onDone: () => setState(() => _running = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final profiles = profilesAsync.valueOrNull ?? const <BackgroundProfile>[];

    return NavigationGuard(
      debugLabel: 'batch',
      canPop: !_running &&
          _files.isEmpty &&
          _profileId == null &&
          _thumbnailPath == null,
      onConfirmLeave: _confirmLeave,
      child: Scaffold(
        appBar: AppBar(title: const Text('Batch processing')),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: _running || _progress != null
              ? _progressView()
              : _selectionView(profiles),
        ),
      ),
    );
  }

  // --- Selection view ---
  Widget _selectionView(List<BackgroundProfile> profiles) {
    BackgroundProfile? selected() {
      for (final pr in profiles) {
        if (pr.id == _profileId) return pr;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Files (${_files.length}/${AppConstants.maxBatchFiles})',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: _files.length >= AppConstants.maxBatchFiles ? null : _addFiles,
              icon: const Icon(Icons.add),
              label: const Text('Add files'),
            ),
          ],
        ),
        Spacing.sm.verticalSpace,
        Expanded(
          child: _files.isEmpty
              ? const Center(child: Text('No files added yet. Tap “Add files”.'))
              : ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.audio_file_outlined),
                    title: Text(_files[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _files.removeAt(i)),
                    ),
                  ),
                ),
        ),
        Spacing.md.verticalSpace,
        DropdownButtonFormField<String>(
          initialValue: _profileId,
          decoration: const InputDecoration(
            labelText: 'Backdrop',
            prefixIcon: Icon(Icons.tune),
          ),
          items: [
            for (final pr in profiles) DropdownMenuItem(value: pr.id, child: Text(pr.name)),
          ],
          onChanged: (id) => setState(() => _profileId = id),
        ),
        Spacing.md.verticalSpace,
        CoverImageCard(
          path: _thumbnailPath,
          onPick: _pickThumbnail,
          onClear: () => setState(() => _thumbnailPath = null),
        ),
        Spacing.md.verticalSpace,
        FilledButton.icon(
          onPressed: (_files.isNotEmpty && selected() != null)
              ? () => _start(selected()!)
              : null,
          icon: const Icon(Icons.auto_fix_high),
          label: Text('Apply to ${_files.length} file${_files.length == 1 ? '' : 's'}'),
        ),
      ],
    );
  }

  // --- Progress / summary view ---
  Widget _progressView() {
    final pr = _progress;
    if (pr == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pr.done) return _summary(pr);

    final fileName =
        pr.currentIndex < _files.length ? _files[pr.currentIndex].name : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${(pr.overall * 100).toStringAsFixed(0)}% overall',
            style: Theme.of(context).textTheme.headlineSmall),
        Spacing.sm.verticalSpace,
        LinearProgressIndicator(value: pr.overall),
        Spacing.lg.verticalSpace,
        Text('File ${pr.currentIndex + 1} of ${pr.total}',
            style: Theme.of(context).textTheme.titleSmall),
        Spacing.xs.verticalSpace,
        Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        Spacing.xs.verticalSpace,
        Text(pr.currentStage.label,
            style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        Spacing.sm.verticalSpace,
        LinearProgressIndicator(
            value: pr.currentFileProgress == 0 ? null : pr.currentFileProgress),
        Spacing.lg.verticalSpace,
        Expanded(child: _resultsList(pr)),
      ],
    );
  }

  Widget _summary(BatchProgress pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
                Spacing.md.horizontalSpace,
                Expanded(
                  child: Text(
                    'Done — ${pr.successCount} succeeded'
                    '${pr.failureCount > 0 ? ', ${pr.failureCount} failed' : ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        Spacing.md.verticalSpace,
        Expanded(child: _resultsList(pr)),
        Spacing.md.verticalSpace,
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _resultsList(BatchProgress pr) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        for (final r in pr.completed)
          ListTile(
            dense: true,
            leading: Icon(
              r.status == JobStatus.success ? Icons.check_circle : Icons.error,
              color: r.status == JobStatus.success ? scheme.primary : scheme.error,
            ),
            title: Text(r.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: r.status == JobStatus.success
                ? Text(p.basename(r.outputPath ?? ''))
                : Text(r.error ?? 'Failed', style: TextStyle(color: scheme.error)),
            trailing: r.status == JobStatus.success && r.outputPath != null
                ? IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () =>
                        ref.read(openFileServiceProvider).open(r.outputPath!),
                  )
                : null,
          ),
      ],
    );
  }
}
