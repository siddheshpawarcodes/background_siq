import 'dataset_file_failure.dart';

/// Streamed snapshot of a Dataset Batch Processing run.
///
/// Mirrors the role of `BatchProgress` for the manual batch flow, but is a
/// separate, additive model so the two features stay independent.
class DatasetBatchProgress {
  const DatasetBatchProgress({
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.successfulFiles = 0,
    this.failedFiles = 0,
    this.skippedFiles = 0,
    this.currentFile,
    this.currentFolder,
    this.currentFileProgress = 0.0,
    this.failures = const [],
    this.scanning = false,
    this.completed = false,
    this.cancelled = false,
    this.noMatchReason,
  });

  /// Total number of matching files discovered (known after scanning).
  final int totalFiles;

  /// Number of files whose processing has finished (success + failure + skip).
  final int processedFiles;

  final int successfulFiles;
  final int failedFiles;

  /// Files that could not be processed for a non-error reason (e.g. the source
  /// disappeared between discovery and processing).
  final int skippedFiles;

  /// Basename of the file currently being processed (null when idle/done).
  final String? currentFile;

  /// Name of the folder containing [currentFile].
  final String? currentFolder;

  /// Progress of the current file, 0..1.
  final double currentFileProgress;

  /// Accumulated per-file failures, for review and retry.
  final List<DatasetFileFailure> failures;

  /// True while the dataset is still being scanned for matches.
  final bool scanning;

  /// True when the whole run has finished (normally or via cancellation).
  final bool completed;

  /// True when the run stopped early because the user cancelled.
  final bool cancelled;

  /// When a completed run found no files to process, a human-readable reason
  /// (e.g. the folder couldn't be read, or audio files were found but none
  /// matched the suffixes). Null whenever files were found or the run is still
  /// in progress.
  final String? noMatchReason;

  /// Overall completion across the dataset, 0..1, smoothed by the in-flight
  /// file's own progress.
  double get overall {
    if (totalFiles == 0) return scanning ? 0 : (completed ? 1 : 0);
    return ((processedFiles + currentFileProgress) / totalFiles).clamp(0.0, 1.0);
  }

  DatasetBatchProgress copyWith({
    int? totalFiles,
    int? processedFiles,
    int? successfulFiles,
    int? failedFiles,
    int? skippedFiles,
    String? currentFile,
    String? currentFolder,
    double? currentFileProgress,
    List<DatasetFileFailure>? failures,
    bool? scanning,
    bool? completed,
    bool? cancelled,
    String? noMatchReason,
  }) =>
      DatasetBatchProgress(
        totalFiles: totalFiles ?? this.totalFiles,
        processedFiles: processedFiles ?? this.processedFiles,
        successfulFiles: successfulFiles ?? this.successfulFiles,
        failedFiles: failedFiles ?? this.failedFiles,
        skippedFiles: skippedFiles ?? this.skippedFiles,
        currentFile: currentFile ?? this.currentFile,
        currentFolder: currentFolder ?? this.currentFolder,
        currentFileProgress: currentFileProgress ?? this.currentFileProgress,
        failures: failures ?? this.failures,
        scanning: scanning ?? this.scanning,
        completed: completed ?? this.completed,
        cancelled: cancelled ?? this.cancelled,
        noMatchReason: noMatchReason ?? this.noMatchReason,
      );
}
