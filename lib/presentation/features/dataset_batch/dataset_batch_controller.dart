import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/dataset_batch_config.dart';
import '../../../domain/entities/dataset_batch_progress.dart';
import '../../../domain/entities/suffix_profile.dart';
import '../../../services/dataset/dataset_batch_cancellation_token.dart';
import 'dataset_batch_state.dart';

final datasetBatchControllerProvider =
    NotifierProvider<DatasetBatchController, DatasetBatchState>(
  DatasetBatchController.new,
);

/// Drives the Dataset Batch Processing screen: collects setup inputs, runs the
/// [ProcessDatasetUseCase], and surfaces live progress. Kept alive so inputs
/// persist across navigation within a session.
class DatasetBatchController extends Notifier<DatasetBatchState> {
  StreamSubscription<DatasetBatchProgress>? _sub;
  DatasetBatchCancellationToken? _token;
  final Stopwatch _stopwatch = Stopwatch();

  /// Dedupes notification updates so we refresh roughly once per file rather
  /// than on every sub-file progress tick.
  String? _lastNotifKey;

  @override
  DatasetBatchState build() {
    ref.onDispose(() {
      _sub?.cancel();
      // If the controller is torn down mid-run, don't leave a dangling
      // foreground service / notification behind.
      unawaited(ref.read(foregroundTaskServiceProvider).stop());
    });
    return const DatasetBatchState();
  }

  void setRootFolder(String path) =>
      state = state.copyWith(rootFolder: path);

  Future<void> pickFolder() async {
    final path = await ref.read(filePickServiceProvider).pickDirectory();
    if (path != null) setRootFolder(path);
  }

  /// Monotonic id source for [SuffixProfileEntry] rows (stable widget keys).
  int _nextEntryId = 0;

  /// Appends a new, empty suffix→profile row for the user to fill in.
  void addEntry() {
    state = state.copyWith(entries: [
      ...state.entries,
      SuffixProfileEntry(id: _nextEntryId++),
    ]);
  }

  void removeEntry(int id) => state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList());

  void setEntrySuffix(int id, String suffix) => _updateEntry(
      id, (e) => e.copyWith(suffix: suffix));

  void setEntryProfile(int id, String profileId) => _updateEntry(
      id, (e) => e.copyWith(profileId: profileId));

  /// Sets or clears the cover-art image (thumbnail) for [id]'s suffix row.
  void setEntryCover(int id, String? coverImagePath) =>
      _updateEntry(id, (e) => e.withCover(coverImagePath));

  /// Opens the image picker and sets the chosen thumbnail on [id]'s row.
  Future<void> pickEntryCover(int id) async {
    final path = await ref.read(filePickServiceProvider).pickImagePath();
    if (path != null) setEntryCover(id, path);
  }

  void _updateEntry(int id, SuffixProfileEntry Function(SuffixProfileEntry) f) {
    state = state.copyWith(
      entries: [
        for (final e in state.entries) if (e.id == id) f(e) else e,
      ],
    );
  }

  /// Builds the run config from the completed rows (suffixes trimmed).
  DatasetBatchConfig _buildConfig() => DatasetBatchConfig(
        rootFolder: state.rootFolder ?? '',
        suffixProfiles: [
          for (final e in state.entries)
            SuffixProfile(
              suffix: e.suffix.trim(),
              profileId: e.profileId!,
              coverImagePath: e.coverImagePath,
            ),
        ],
      );

  /// Starts a fresh run over the whole dataset.
  Future<void> start() async {
    AppLogger.i('START tapped (canStart=${state.canStart}).');
    if (!state.canStart) return;
    final config = _buildConfig();
    AppLogger.i('Ensuring storage access…');
    await _ensureStorageAccess();
    AppLogger.i('Starting foreground service…');
    await _startForegroundService();
    AppLogger.i('Pre-flight done; launching run.');
    _run(config);
  }

  /// Re-runs only the files that failed in the most recent run.
  Future<void> retryFailed() async {
    final failures = state.progress?.failures ?? const [];
    if (failures.isEmpty || state.running) return;
    final config = _buildConfig();
    await _ensureStorageAccess();
    await _startForegroundService();
    _run(config, onlyPaths: failures.map((f) => f.filePath).toList());
  }

  /// Requests access to public storage so output can land in `Music/EchoBug/`.
  /// Best-effort: if denied, the file system falls back to app-private storage
  /// and the run still completes.
  Future<void> _ensureStorageAccess() =>
      ref.read(storagePermissionServiceProvider).ensurePublicStorageAccess();

  /// Starts the Android foreground service so the run survives backgrounding
  /// and the user can't accidentally kill it. Best-effort and a no-op off
  /// Android (the run still proceeds either way).
  Future<void> _startForegroundService() async {
    _lastNotifKey = null;
    await ref.read(foregroundTaskServiceProvider).start(
          title: 'Processing dataset',
          text: 'Preparing…',
        );
  }

  Future<void> _stopForegroundService() =>
      ref.read(foregroundTaskServiceProvider).stop();

  /// Refreshes the ongoing notification, but only when the file count or folder
  /// changes — not on every sub-file progress tick.
  void _updateNotification(DatasetBatchProgress p) {
    final String text;
    if (p.scanning) {
      text = 'Scanning files…';
    } else if (p.completed) {
      return; // The service is stopped on completion; no final update needed.
    } else {
      final folder = p.currentFolder == null ? '' : ' • ${p.currentFolder}';
      text = '${p.processedFiles}/${p.totalFiles} files$folder';
    }
    if (text == _lastNotifKey) return;
    _lastNotifKey = text;
    unawaited(ref
        .read(foregroundTaskServiceProvider)
        .update(title: 'Processing dataset', text: text));
  }

  void _run(DatasetBatchConfig config, {List<String>? onlyPaths}) {
    _sub?.cancel();
    _token = DatasetBatchCancellationToken();
    _stopwatch
      ..reset()
      ..start();

    state = state.copyWith(running: true, progress: null, elapsed: Duration.zero);

    final stream = ref.read(processDatasetUseCaseProvider).call(
          config,
          cancelToken: _token,
          onlyPaths: onlyPaths,
        );

    _sub = stream.listen(
      (progress) {
        AppLogger.d('STATE_UPDATED scanning=${progress.scanning} '
            'overall=${progress.overall.toStringAsFixed(2)} '
            'processed=${progress.processedFiles}/${progress.totalFiles} '
            'ok=${progress.successfulFiles} fail=${progress.failedFiles} '
            'file=${progress.currentFile ?? '-'} '
            'stage=${progress.currentStage ?? '-'}');
        state = state.copyWith(
          progress: progress,
          elapsed: _stopwatch.elapsed,
        );
        _updateNotification(progress);
      },
      onDone: () {
        AppLogger.i('RUN_DONE (stream closed normally).');
        _stopwatch.stop();
        state = state.copyWith(running: false, elapsed: _stopwatch.elapsed);
        unawaited(_stopForegroundService());
      },
      onError: (Object error, StackTrace st) {
        AppLogger.e('RUN_ERROR: $error', error: error, stackTrace: st);
        _stopwatch.stop();
        state = state.copyWith(running: false, elapsed: _stopwatch.elapsed);
        unawaited(_stopForegroundService());
      },
    );
  }

  /// Requests cancellation; the in-flight file finishes before the run stops.
  void cancel() => _token?.cancel();

  /// Clears the run state (keeps setup inputs) so the user can configure again.
  void reset() {
    _sub?.cancel();
    unawaited(_stopForegroundService());
    state = state.clearedRun();
  }
}
