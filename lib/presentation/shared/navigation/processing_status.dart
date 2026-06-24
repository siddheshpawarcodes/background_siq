import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dataset_batch/dataset_batch_controller.dart';
import '../../features/processing/processing_queue_controller.dart';
import '../../features/processing/single_apply_controller.dart';

/// The background-capable processing engines that can hold the single Android
/// foreground service. (The manual `BatchScreen` runs screen-locally and blocks
/// navigation while active, so it can't overlap these and isn't listed.)
enum ProcessingEngine { singleApply, batchQueue, dataset }

/// Which engine (if any) currently owns active processing. Drives
/// Processing-Aware Navigation: we allow only one active engine at a time so we
/// never spin up duplicate foreground services / FFmpeg pipelines.
final processingStatusProvider = Provider<ProcessingEngine?>((ref) {
  if (ref.watch(datasetBatchControllerProvider).running) {
    return ProcessingEngine.dataset;
  }
  if (ref.watch(singleApplyControllerProvider).running) {
    return ProcessingEngine.singleApply;
  }
  if (ref.watch(processingQueueProvider).isNotEmpty) {
    return ProcessingEngine.batchQueue;
  }
  return null;
});

/// True when an engine *other than* [excluding] is currently processing. Call
/// before starting a new job; if true, refuse and tell the user (see
/// `showAlreadyRunningMessage`).
bool otherEngineActive(WidgetRef ref, {required ProcessingEngine excluding}) {
  final active = ref.read(processingStatusProvider);
  return active != null && active != excluding;
}

/// True when any background-capable engine is processing. Used by flows that
/// aren't themselves one of the [ProcessingEngine]s (e.g. the manual batch).
bool anyEngineActive(WidgetRef ref) => ref.read(processingStatusProvider) != null;
