import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/dataset_batch_config.dart';
import '../../../domain/entities/dataset_batch_progress.dart';
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

  @override
  DatasetBatchState build() {
    ref.onDispose(() => _sub?.cancel());
    return const DatasetBatchState();
  }

  void setRootFolder(String path) =>
      state = state.copyWith(rootFolder: path);

  Future<void> pickFolder() async {
    final path = await ref.read(filePickServiceProvider).pickDirectory();
    if (path != null) setRootFolder(path);
  }

  /// Adds a suffix to the match set. Trims whitespace and ignores empties and
  /// duplicates. Returns false if nothing was added.
  bool addSuffix(String suffix) {
    final trimmed = suffix.trim();
    if (trimmed.isEmpty || state.suffixes.contains(trimmed)) return false;
    state = state.copyWith(suffixes: [...state.suffixes, trimmed]);
    return true;
  }

  void removeSuffix(String suffix) => state =
      state.copyWith(suffixes: state.suffixes.where((s) => s != suffix).toList());

  void selectProfile(String id) => state = state.copyWith(profileId: id);

  /// Starts a fresh run over the whole dataset.
  Future<void> start() async {
    if (!state.canStart) return;
    final config = DatasetBatchConfig(
      rootFolder: state.rootFolder!,
      selectedSuffixes: List.of(state.suffixes),
      profileId: state.profileId!,
    );
    await _ensureStorageAccess();
    _run(config);
  }

  /// Re-runs only the files that failed in the most recent run.
  Future<void> retryFailed() async {
    final failures = state.progress?.failures ?? const [];
    if (failures.isEmpty || state.running) return;
    final config = DatasetBatchConfig(
      rootFolder: state.rootFolder ?? '',
      selectedSuffixes: List.of(state.suffixes),
      profileId: state.profileId ?? '',
    );
    await _ensureStorageAccess();
    _run(config, onlyPaths: failures.map((f) => f.filePath).toList());
  }

  /// Requests access to public storage so output can land in `Music/EchoBug/`.
  /// Best-effort: if denied, the file system falls back to app-private storage
  /// and the run still completes.
  Future<void> _ensureStorageAccess() =>
      ref.read(storagePermissionServiceProvider).ensurePublicStorageAccess();

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
      (progress) => state = state.copyWith(
        progress: progress,
        elapsed: _stopwatch.elapsed,
      ),
      onDone: () {
        _stopwatch.stop();
        state = state.copyWith(running: false, elapsed: _stopwatch.elapsed);
      },
      onError: (_) {
        _stopwatch.stop();
        state = state.copyWith(running: false, elapsed: _stopwatch.elapsed);
      },
    );
  }

  /// Requests cancellation; the in-flight file finishes before the run stops.
  void cancel() => _token?.cancel();

  /// Clears the run state (keeps setup inputs) so the user can configure again.
  void reset() {
    _sub?.cancel();
    state = state.clearedRun();
  }
}
