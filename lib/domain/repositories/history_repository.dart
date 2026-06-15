import '../entities/history_entry.dart';

/// Persistence contract for processing history (SRS §7.3, §11.5).
abstract interface class HistoryRepository {
  /// Emits history (newest first) on every change.
  Stream<List<HistoryEntry>> watchAll();

  /// One-shot read (newest first).
  Future<List<HistoryEntry>> getAll();

  /// Appends an entry.
  Future<void> add(HistoryEntry entry);

  /// Removes all history.
  Future<void> clear();
}
