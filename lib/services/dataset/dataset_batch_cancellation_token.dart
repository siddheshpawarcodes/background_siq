/// Cooperative cancellation flag for a dataset batch run.
///
/// The processor checks [isCancelled] between files: the in-flight file always
/// finishes cleanly (so no partial/corrupt output is left behind), then the
/// loop terminates. Cancellation is one-way and safe to call from the UI.
class DatasetBatchCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}
