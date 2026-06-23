import '../../../domain/entities/dataset_batch_progress.dart';

/// One editable row on the Dataset Batch setup screen: a filename suffix paired
/// with the profile to apply to files matching it. Both may be incomplete while
/// the user is still filling the form (empty suffix, unselected profile); the
/// row only counts toward [DatasetBatchState.canStart] once both are set.
class SuffixProfileEntry {
  const SuffixProfileEntry({
    required this.id,
    this.suffix = '',
    this.profileId,
  });

  /// Stable identity for widget keys / controller lifecycle. Survives edits and
  /// reordering so the row's text field keeps its state across rebuilds.
  final int id;

  /// The filename suffix the user typed, e.g. `_eng` (may be empty/untrimmed).
  final String suffix;

  /// Selected profile id, or null until the user picks one.
  final String? profileId;

  bool get isComplete => suffix.trim().isNotEmpty && profileId != null;

  SuffixProfileEntry copyWith({String? suffix, String? profileId}) =>
      SuffixProfileEntry(
        id: id,
        suffix: suffix ?? this.suffix,
        profileId: profileId ?? this.profileId,
      );
}

/// UI state for the Dataset Batch Processing screen.
///
/// Holds the user's setup inputs (folder + suffix→profile rows) plus the live
/// run state. The backing controller is kept alive, so inputs survive
/// navigation within a session.
class DatasetBatchState {
  const DatasetBatchState({
    this.rootFolder,
    this.entries = const [],
    this.running = false,
    this.progress,
    this.elapsed,
  });

  /// Selected dataset root folder (null until chosen).
  final String? rootFolder;

  /// Suffix→profile rows, e.g. `_eng`→Corporate, `_hin`→Podcast.
  final List<SuffixProfileEntry> entries;

  /// True while a run is in progress.
  final bool running;

  /// Latest progress snapshot (null before the first run).
  final DatasetBatchProgress? progress;

  /// Wall-clock duration of the most recent run (set when it completes).
  final Duration? elapsed;

  /// Trimmed suffixes that appear more than once — duplicates are ambiguous and
  /// block starting a run.
  Set<String> get duplicateSuffixes {
    final seen = <String>{};
    final dups = <String>{};
    for (final e in entries) {
      final s = e.suffix.trim();
      if (s.isEmpty) continue;
      if (!seen.add(s)) dups.add(s);
    }
    return dups;
  }

  bool get canStart =>
      !running &&
      rootFolder != null &&
      entries.isNotEmpty &&
      entries.every((e) => e.isComplete) &&
      duplicateSuffixes.isEmpty;

  DatasetBatchState copyWith({
    String? rootFolder,
    List<SuffixProfileEntry>? entries,
    bool? running,
    DatasetBatchProgress? progress,
    Duration? elapsed,
  }) =>
      DatasetBatchState(
        rootFolder: rootFolder ?? this.rootFolder,
        entries: entries ?? this.entries,
        running: running ?? this.running,
        progress: progress ?? this.progress,
        elapsed: elapsed ?? this.elapsed,
      );

  /// Resets only the run state, preserving the setup inputs.
  DatasetBatchState clearedRun() => DatasetBatchState(
        rootFolder: rootFolder,
        entries: entries,
      );
}
