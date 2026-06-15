import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/processing_job.dart';

/// Arguments handed to the processing screen via the router (SRS §12).
class ApplyArgs {
  const ApplyArgs({required this.source, required this.profile});
  final AudioFileRef source;
  final BackgroundProfile profile;
}

/// Processing screen — live stage list + percentage progress (SRS §11.2).
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.args});

  final ApplyArgs args;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  StreamSubscription<ProcessingJob>? _sub;
  ProcessingJob? _job;

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

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final stream = ref
        .read(applyProfileUseCaseProvider)
        .call(widget.args.source, widget.args.profile);
    _sub = stream.listen((job) {
      setState(() => _job = job);
      if (job.stage == JobStage.completed && job.outputPath != null) {
        _maybeAutoOpen(job.outputPath!);
      }
    });
  }

  Future<void> _maybeAutoOpen(String path) async {
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

  /// Cancels the running native FFmpeg session and leaves the screen.
  Future<void> _cancel() async {
    final id = _job?.id;
    await _sub?.cancel();
    if (id != null) await ref.read(audioProcessorProvider).cancel(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get _done => _job?.stage == JobStage.completed;
  bool get _failed => _job?.stage == JobStage.failed;

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return PopScope(
      canPop: _done || _failed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processing'),
          automaticallyImplyLeading: _done || _failed,
        ),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: _failed
              ? _ResultCard.failure(message: job?.errorMessage ?? 'Processing failed.', onBack: _pop)
              : _done
                  ? _ResultCard.success(
                      outputPath: job!.outputPath!,
                      onDone: _pop,
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
        const SizedBox(height: Spacing.sm),
        LinearProgressIndicator(value: job?.progress == 0 ? null : job?.progress),
        const SizedBox(height: Spacing.lg),
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
            onPressed: _cancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  void _pop() => Navigator.of(context).pop();
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
          const SizedBox(height: Spacing.md),
          Text(
            isSuccess ? 'Completed' : 'Failed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          if (isSuccess)
            Text('Saved as ${p.basename(outputPath!)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium)
          else
            Text(message!, textAlign: TextAlign.center),
          const SizedBox(height: Spacing.xl),
          if (isSuccess) ...[
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open file'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(onPressed: onDone, child: const Text('Done')),
          ] else
            FilledButton(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    );
  }
}
