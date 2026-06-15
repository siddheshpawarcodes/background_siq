import 'package:hive_ce/hive.dart';

import '../../domain/entities/audio_file_ref.dart';
import '../../domain/repositories/recent_files_repository.dart';
import '../mappers/recent_file_mapper.dart';
import '../models/recent_file_model.dart';

/// Hive-backed implementation of [RecentFilesRepository] (SRS §7.3).
/// Keeps at most [_maxEntries] most-recently-used files, keyed by path.
class RecentFilesRepositoryImpl implements RecentFilesRepository {
  RecentFilesRepositoryImpl(this._box);

  final Box<RecentFileModel> _box;
  static const int _maxEntries = 20;

  String _key(String path) => path.hashCode.toRadixString(16);

  List<AudioFileRef> _readAll() {
    final list = _box.values.toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed)); // most recent first
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AudioFileRef>> recent() async => _readAll();

  @override
  Stream<List<AudioFileRef>> watch() async* {
    yield _readAll();
    yield* _box.watch().map((_) => _readAll());
  }

  @override
  Future<void> push(AudioFileRef file) async {
    await _box.put(_key(file.path), file.toModel(lastUsed: DateTime.now()));
    // Trim oldest beyond the cap.
    if (_box.length > _maxEntries) {
      final models = _box.toMap().entries.toList()
        ..sort((a, b) => a.value.lastUsed.compareTo(b.value.lastUsed));
      final excess = _box.length - _maxEntries;
      await _box.deleteAll(models.take(excess).map((e) => e.key));
    }
  }

  @override
  Future<void> clear() async => _box.clear();
}
