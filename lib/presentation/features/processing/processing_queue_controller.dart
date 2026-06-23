import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/audio_file_ref.dart';
import '../../../domain/entities/background_profile.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/processing_job.dart';

/// Lifecycle of a single edit handed to the background queue.
enum QueuedJobStatus { queued, running }

/// One edit waiting in (or running through) the background processing queue.
///
/// Terminal jobs are *not* represented here — once an edit completes or fails,
/// [ApplyProfileUseCase] has already written a [HistoryEntry], so the queue
/// drops it and the History screen becomes the record of the outcome.
class QueuedJob {
  const QueuedJob({
    required this.id,
    required this.source,
    required this.profile,
    this.status = QueuedJobStatus.queued,
    this.stage = JobStage.preparing,
    this.progress = 0,
    this.ffmpegJobId,
  });

  /// Stable queue identifier (independent of the engine's per-run job id).
  final String id;
  final AudioFileRef source;
  final BackgroundProfile profile;
  final QueuedJobStatus status;
  final JobStage stage;
  final double progress; // 0..1

  /// The engine job id, known once processing starts; used to cancel the
  /// native FFmpeg session.
  final String? ffmpegJobId;

  bool get isRunning => status == QueuedJobStatus.running;

  QueuedJob copyWith({
    QueuedJobStatus? status,
    JobStage? stage,
    double? progress,
    String? ffmpegJobId,
  }) =>
      QueuedJob(
        id: id,
        source: source,
        profile: profile,
        status: status ?? this.status,
        stage: stage ?? this.stage,
        progress: progress ?? this.progress,
        ffmpegJobId: ffmpegJobId ?? this.ffmpegJobId,
      );
}

/// Snapshot of the background queue, consumed by the app-wide banner and the
/// History "Processing" section.
class ProcessingQueueState {
  const ProcessingQueueState({this.jobs = const []});

  /// Active jobs only (queued + running), oldest first.
  final List<QueuedJob> jobs;

  bool get isEmpty => jobs.isEmpty;
  bool get isNotEmpty => jobs.isNotEmpty;
  int get count => jobs.length;

  QueuedJob? get running {
    for (final j in jobs) {
      if (j.isRunning) return j;
    }
    return null;
  }
}

final processingQueueProvider =
    NotifierProvider<ProcessingQueueController, ProcessingQueueState>(
  ProcessingQueueController.new,
);

/// App-scoped queue that runs profile edits **detached from any screen**, one
/// at a time, so the user can keep recording while edits process in the
/// background. Drives the Android foreground service for the duration of a run.
///
/// Engine work ([ApplyProfileUseCase] → FFmpeg) already executes off the UI
/// isolate; this controller's job is to own the subscription beyond a screen's
/// lifetime, surface progress, and chain queued jobs sequentially.
class ProcessingQueueController extends Notifier<ProcessingQueueState> {
  static const _uuid = Uuid();

  StreamSubscription<ProcessingJob>? _sub;
  bool _busy = false;

  @override
  ProcessingQueueState build() => const ProcessingQueueState();

  /// Adds an edit to the queue and starts processing if idle. Returns the
  /// queue id for the new job.
  String enqueue(AudioFileRef source, BackgroundProfile profile) {
    final job = QueuedJob(id: _uuid.v4(), source: source, profile: profile);
    state = ProcessingQueueState(jobs: [...state.jobs, job]);
    _drain();
    return job.id;
  }

  /// Cancels a job. A running job's native session is aborted; a queued job is
  /// simply removed.
  Future<void> cancel(String id) async {
    final job = _job(id);
    if (job == null) return;
    if (job.isRunning) {
      final ffmpegId = job.ffmpegJobId;
      if (ffmpegId != null) {
        await ref.read(audioProcessorProvider).cancel(ffmpegId);
      }
      await _sub?.cancel();
      _sub = null;
      _busy = false;
      _remove(id);
      _drain();
    } else {
      _remove(id);
    }
  }

  // --- internals ---

  void _drain() {
    if (_busy) return;
    final next = _firstQueued();
    if (next == null) {
      // Nothing left to do — tear down the foreground service.
      ref.read(foregroundTaskServiceProvider).stop();
      return;
    }
    _busy = true;
    _runJob(next);
  }

  void _runJob(QueuedJob job) {
    _patch(job.id, (j) => j.copyWith(status: QueuedJobStatus.running));
    _startForeground(job.id);

    final stream = ref
        .read(applyProfileUseCaseProvider)
        .call(job.source, job.profile);

    _sub = stream.listen(
      (pj) {
        // Keep state in sync with engine progress. We never cancel on the
        // `completed` event: ApplyProfileUseCase writes its HistoryEntry *after*
        // the stream's final yield, so we must let it run to onDone.
        _patch(
          job.id,
          (j) => j.copyWith(
            ffmpegJobId: pj.id,
            stage: pj.stage,
            progress: pj.stage == JobStage.completed ? 1.0 : pj.progress,
          ),
        );
        _updateForeground(job.id);
      },
      onError: (_) => _finalize(job.id),
      onDone: () => _finalize(job.id),
      cancelOnError: false,
    );
  }

  /// Drops the just-finished job and advances the queue. Safe to call from
  /// onDone (subscription already complete) or onError.
  Future<void> _finalize(String id) async {
    await _sub?.cancel();
    _sub = null;
    _busy = false;
    _remove(id);
    _drain();
  }

  // --- foreground notification ---

  void _startForeground(String id) {
    final job = _job(id);
    if (job == null) return;
    ref.read(foregroundTaskServiceProvider).start(
          title: _notifTitle(),
          text: _notifText(job),
        );
  }

  void _updateForeground(String id) {
    final job = _job(id);
    if (job == null) return;
    ref.read(foregroundTaskServiceProvider).update(
          title: _notifTitle(),
          text: _notifText(job),
        );
  }

  String _notifTitle() =>
      state.count > 1 ? 'Processing ${state.count} recordings' : 'Processing recording';

  String _notifText(QueuedJob job) =>
      '${job.source.name} · ${job.stage.label} ${(job.progress * 100).round()}%';

  // --- list helpers ---

  QueuedJob? _job(String id) {
    for (final j in state.jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  QueuedJob? _firstQueued() {
    for (final j in state.jobs) {
      if (j.status == QueuedJobStatus.queued) return j;
    }
    return null;
  }

  void _patch(String id, QueuedJob Function(QueuedJob) update) {
    state = ProcessingQueueState(
      jobs: [for (final j in state.jobs) if (j.id == id) update(j) else j],
    );
  }

  void _remove(String id) {
    state = ProcessingQueueState(
      jobs: [for (final j in state.jobs) if (j.id != id) j],
    );
  }
}
