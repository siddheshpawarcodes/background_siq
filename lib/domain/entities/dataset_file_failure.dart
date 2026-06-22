/// Records a single file that failed during a dataset batch run, so the user
/// can review and optionally retry it. A failure of one file never aborts the
/// rest of the dataset.
class DatasetFileFailure {
  const DatasetFileFailure({
    required this.filePath,
    required this.error,
    this.fileName,
    this.stackTrace,
  });

  /// Absolute path of the file that failed.
  final String filePath;

  /// User-facing error message.
  final String error;

  /// Basename of [filePath], convenient for display.
  final String? fileName;

  /// Captured stack trace when the failure was an unexpected exception.
  final String? stackTrace;
}
