import '../../../domain/entities/dataset_batch_progress.dart';

/// UI state for the Dataset Batch Processing screen.
///
/// Holds the user's setup inputs (folder, suffixes, profile) plus the live run
/// state. The backing controller is kept alive, so inputs survive navigation
/// within a session.
class DatasetBatchState {
  const DatasetBatchState({
    this.rootFolder,
    this.suffixes = const [],
    this.profileId,
    this.running = false,
    this.progress,
    this.elapsed,
  });

  /// Selected dataset root folder (null until chosen).
  final String? rootFolder;

  /// Filename suffixes to match, e.g. `_eng`, `_hin`, `_san`.
  final List<String> suffixes;

  /// Selected profile id (null until chosen).
  final String? profileId;

  /// True while a run is in progress.
  final bool running;

  /// Latest progress snapshot (null before the first run).
  final DatasetBatchProgress? progress;

  /// Wall-clock duration of the most recent run (set when it completes).
  final Duration? elapsed;

  bool get canStart =>
      !running &&
      rootFolder != null &&
      suffixes.isNotEmpty &&
      profileId != null;

  DatasetBatchState copyWith({
    String? rootFolder,
    List<String>? suffixes,
    String? profileId,
    bool? running,
    DatasetBatchProgress? progress,
    Duration? elapsed,
  }) =>
      DatasetBatchState(
        rootFolder: rootFolder ?? this.rootFolder,
        suffixes: suffixes ?? this.suffixes,
        profileId: profileId ?? this.profileId,
        running: running ?? this.running,
        progress: progress ?? this.progress,
        elapsed: elapsed ?? this.elapsed,
      );

  /// Resets only the run state, preserving the setup inputs.
  DatasetBatchState clearedRun() => DatasetBatchState(
        rootFolder: rootFolder,
        suffixes: suffixes,
        profileId: profileId,
      );
}
