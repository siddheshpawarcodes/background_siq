import 'package:echobug/presentation/features/dataset_batch/dataset_batch_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the back-button "Leave Dataset Setup?" trigger: the navigation guard
/// pops freely only when [DatasetBatchState.hasSetupInput] is false.
void main() {
  group('DatasetBatchState.hasSetupInput', () {
    test('is false for a fresh, untouched state', () {
      expect(const DatasetBatchState().hasSetupInput, isFalse);
    });

    test('is true once a root folder is selected', () {
      expect(
        const DatasetBatchState(rootFolder: '/data').hasSetupInput,
        isTrue,
      );
    });

    test('is true once a suffix row is added (even if empty)', () {
      const state = DatasetBatchState(entries: [SuffixProfileEntry(id: 0)]);
      expect(state.hasSetupInput, isTrue);
    });

    test('is false again after clearedRun() with no setup inputs', () {
      const ran = DatasetBatchState(running: true);
      expect(ran.clearedRun().hasSetupInput, isFalse);
    });

    test('clearedRun() preserves setup inputs (so the guard still fires)', () {
      const ran = DatasetBatchState(
        rootFolder: '/data',
        entries: [SuffixProfileEntry(id: 0, suffix: '_eng', profileId: 'p1')],
        running: true,
      );
      final cleared = ran.clearedRun();
      expect(cleared.running, isFalse);
      expect(cleared.hasSetupInput, isTrue);
    });
  });
}
