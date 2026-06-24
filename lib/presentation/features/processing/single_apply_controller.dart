import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/processing_job.dart';

/// Arguments to start a single-file profile-apply run (handed over from Home).
class ApplyArgs {
  const ApplyArgs({required this.source, required this.profile});
  final AudioFileRef source;
  final BackgroundProfile profile;
}

/// UI state for the single-file Apply flow.
class SingleApplyState {
  const SingleApplyState({this.job, this.running = false});

  /// Latest engine snapshot (null before the first run / after a reset). The
  /// terminal job is retained so the screen can show the success/failure card.
  final ProcessingJob? job;

  /// True while a run is in progress (not yet completed / failed / cancelled).
  final bool running;

  bool get isCompleted => job?.stage == JobStage.completed;
  bool get isFailed => job?.stage == JobStage.failed;
}

final singleApplyControllerProvider =
    NotifierProvider<SingleApplyController, SingleApplyState>(
  SingleApplyController.new,
);

/// Owns a single-file profile-apply run **detached from the screen**, so the
/// user can leave the processing screen and let it finish in the background
/// (Android foreground service + progress notification). Mirrors
/// [DatasetBatchController] but for one [ApplyProfileUseCase] run.
///
/// App-scoped (kept alive), which is what lets the job outlive the screen —
/// the old screen-local subscription was cancelled on `dispose`, which is why
/// leaving used to kill the job.
class SingleApplyController extends Notifier<SingleApplyState> {
  StreamSubscription<ProcessingJob>? _sub;

  @override
  SingleApplyState build() {
    ref.onDispose(() {
      _sub?.cancel();
      // Never leave a dangling foreground service / notification behind.
      ref.read(foregroundTaskServiceProvider).stop();
    });
    return const SingleApplyState();
  }

  /// Starts a run. No-op if one is already in flight (prevents duplicate
  /// pipelines).
  void start(ApplyArgs args) {
    if (state.running) return;
    _sub?.cancel();
    state = const SingleApplyState(running: true);

    // Best-effort; keeps the run alive when backgrounded (no-op off Android).
    ref.read(foregroundTaskServiceProvider).start(
          title: 'Processing recording',
          text: '${args.source.name} · preparing…',
        );

    final stream =
        ref.read(applyProfileUseCaseProvider).call(args.source, args.profile);

    _sub = stream.listen(
      (job) {
        // Never cancel on the `completed` event: ApplyProfileUseCase writes its
        // HistoryEntry *after* the stream's final yield, so we let it reach
        // onDone (same invariant as ProcessingQueueController).
        state = SingleApplyState(job: job, running: true);
        _updateForeground(job);
      },
      onError: (Object _, StackTrace _) => _finish(),
      onDone: _finish,
      cancelOnError: false,
    );
  }

  /// Marks the run finished, keeping the terminal [SingleApplyState.job] so the
  /// screen can show its success/failure card, and tears down the service.
  void _finish() {
    state = SingleApplyState(job: state.job, running: false);
    ref.read(foregroundTaskServiceProvider).stop();
  }

  void _updateForeground(ProcessingJob job) {
    if (job.stage == JobStage.completed || job.stage == JobStage.failed) return;
    ref.read(foregroundTaskServiceProvider).update(
          title: 'Processing recording',
          text: '${job.source.name} · ${job.stage.label} '
              '${(job.progress * 100).round()}%',
        );
  }

  /// Cancels the in-flight run (aborts the native FFmpeg session) and stops the
  /// foreground service.
  Future<void> cancel() async {
    final id = state.job?.id;
    await _sub?.cancel();
    _sub = null;
    if (id != null) await ref.read(audioProcessorProvider).cancel(id);
    await ref.read(foregroundTaskServiceProvider).stop();
    state = const SingleApplyState();
  }

  /// Clears terminal state so the next Apply starts fresh. No-op while running.
  void reset() {
    if (state.running) return;
    state = const SingleApplyState();
  }
}
