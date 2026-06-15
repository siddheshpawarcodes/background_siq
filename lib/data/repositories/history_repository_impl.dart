import 'package:hive_ce/hive.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../mappers/history_mapper.dart';
import '../models/history_model.dart';

/// Hive-backed implementation of [HistoryRepository] (SRS §7.3).
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._box);

  final Box<HistoryModel> _box;

  List<HistoryEntry> _readAll() {
    final list = _box.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
    return list;
  }

  @override
  Stream<List<HistoryEntry>> watchAll() async* {
    yield _readAll();
    yield* _box.watch().map((_) => _readAll());
  }

  @override
  Future<List<HistoryEntry>> getAll() async => _readAll();

  @override
  Future<void> add(HistoryEntry entry) async {
    await _box.put(entry.id, entry.toModel());
  }

  @override
  Future<void> clear() async => _box.clear();
}
