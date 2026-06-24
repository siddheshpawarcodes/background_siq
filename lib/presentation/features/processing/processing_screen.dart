import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/processing_job.dart';
import '../../shared/navigation/nav_log.dart';
import '../../shared/navigation/navigation_dialogs.dart';
import '../../shared/navigation/navigation_guard.dart';
import 'single_apply_controller.dart';

/// Processing screen — live stage list + percentage progress (SRS §11.2).
///
/// A thin *observer* of [SingleApplyController]: the run lives in the
/// controller (backed by the foreground service), so leaving this screen lets
/// it finish in the background instead of cancelling it.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  /// Guards the one-shot auto-open of a successfully exported file.
  bool _autoOpened = false;

  /// Visible pipeline stages, in order.
  static const _stages = [
    JobStage.preparing,
    JobStage.denoising,
    JobStage.enhancing,
    JobStage.mixing,
    JobStage.ducking,
    JobStage.fading,
    JobStage.normalizing,
    JobStage.exporting,
  ];

  Future<void> _maybeAutoOpen(String path) async {
    if (_autoOpened) return;
    _autoOpened = true;
    final settings = await ref.read(settingsRepositoryProvider).get();
    if (settings.autoOpenOutputFolder) await _open(path);
  }

  Future<void> _open(String path) async {
    final result = await ref.read(openFileServiceProvider).open(path);
    if (mounted && result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file.')),
      );
    }
  }

  /// Decides what happens on a back press while a run is active. Leaving in the
  /// background keeps the controller + foreground service running.
  Future<bool> _confirmLeave() async {
    if (!ref.read(singleApplyControllerProvider).running) return true;
    final action = await showProcessingRunningDialog(context, canBackground: true);
    switch (action) {
      case LeaveAction.background:
        NavLog.event(NavEvent.processingScreenExited, 'single/background');
        return true;
      case LeaveAction.cancel:
        await ref.read(singleApplyControllerProvider.notifier).cancel();
        return true;
      case LeaveAction.stay:
        return false;
    }
  }

  /// Cancel button on the in-progress view: stop the job and leave.
  Future<void> _cancelAndPop() async {
    await ref.read(singleApplyControllerProvider.notifier).cancel();
    if (mounted) Navigator.of(context).pop();
  }

  /// Done/Back on the result card: clear terminal state and leave.
  void _done() {
    ref.read(singleApplyControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singleApplyControllerProvider);
    final job = state.job;
    final done = state.isCompleted;
    final failed = state.isFailed;

    // Auto-open the export once, after the frame, if the user opted in.
    if (done && job?.outputPath != null && !_autoOpened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeAutoOpen(job!.outputPath!);
      });
    }

    return NavigationGuard(
      debugLabel: 'single-processing',
      canPop: !state.running,
      onConfirmLeave: _confirmLeave,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processing'),
          automaticallyImplyLeading: !state.running,
        ),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: failed
              ? _ResultCard.failure(message: job?.errorMessage ?? 'Processing failed.', onBack: _done)
              : done
                  ? _ResultCard.success(
                      outputPath: job!.outputPath!,
                      onDone: _done,
                      onOpen: () => _open(job.outputPath!),
                    )
                  : _progressView(job),
        ),
      ),
    );
  }

  Widget _progressView(ProcessingJob? job) {
    final currentIndex = job == null ? 0 : _stages.indexOf(job.stage);
    final percent = ((job?.progress ?? 0) * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$percent%', style: Theme.of(context).textTheme.displaySmall),
        Spacing.sm.verticalSpace,
        LinearProgressIndicator(value: job?.progress == 0 ? null : job?.progress),
        Spacing.lg.verticalSpace,
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < _stages.length; i++)
                _StageRow(
                  label: _stages[i].label,
                  state: i < currentIndex
                      ? _StepState.done
                      : (i == currentIndex ? _StepState.active : _StepState.pending),
                ),
            ],
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: _cancelAndPop,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}

enum _StepState { pending, active, done }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.label, required this.state});
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (state) {
      _StepState.done => (Icons.check_circle, scheme.primary),
      _StepState.active => (Icons.autorenew, scheme.primary),
      _StepState.pending => (Icons.radio_button_unchecked, scheme.outlineVariant),
    };
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: state == _StepState.pending ? scheme.outline : scheme.onSurface,
          fontWeight: state == _StepState.active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard.success({
    required this.outputPath,
    required this.onDone,
    required this.onOpen,
  })  : isSuccess = true,
        message = null,
        onBack = null;

  const _ResultCard.failure({required this.message, required this.onBack})
      : isSuccess = false,
        outputPath = null,
        onDone = null,
        onOpen = null;

  final bool isSuccess;
  final String? outputPath;
  final String? message;
  final VoidCallback? onDone;
  final VoidCallback? onBack;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            size: 72,
            color: isSuccess ? scheme.primary : scheme.error,
          ),
          Spacing.md.verticalSpace,
          Text(
            isSuccess ? 'Completed' : 'Failed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Spacing.sm.verticalSpace,
          if (isSuccess)
            Text('Saved as ${p.basename(outputPath!)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium)
          else
            Text(message!, textAlign: TextAlign.center),
          Spacing.xl.verticalSpace,
          if (isSuccess) ...[
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open file'),
            ),
            Spacing.sm.verticalSpace,
            TextButton(onPressed: onDone, child: const Text('Done')),
          ] else
            FilledButton(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    );
  }
}
