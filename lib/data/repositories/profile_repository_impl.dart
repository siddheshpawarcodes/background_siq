import 'package:hive_ce/hive.dart';

import '../../core/errors/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/background_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mappers/profile_mapper.dart';
import '../models/profile_model.dart';

/// Hive-backed implementation of [ProfileRepository] (SRS §7.3).
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._box);

  final Box<ProfileModel> _box;

  List<BackgroundProfile> _readAll() {
    final list = _box.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Stream<List<BackgroundProfile>> watchAll() async* {
    yield _readAll();
    yield* _box.watch().map((_) => _readAll());
  }

  @override
  Future<List<BackgroundProfile>> getAll() async => _readAll();

  @override
  Future<Result<BackgroundProfile>> getById(String id) async {
    final model = _box.get(id);
    if (model == null) return const Result.err(ProfileNotFoundFailure());
    return Result.ok(model.toEntity());
  }

  @override
  BackgroundProfile? getByIdSync(String id) => _box.get(id)?.toEntity();

  @override
  Future<Result<void>> save(BackgroundProfile profile) async {
    try {
      await _box.put(profile.id, profile.toModel());
      return const Result.ok(null);
    } catch (e) {
      return Result.err(UnknownFailure(debugDetail: e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _box.delete(id);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(UnknownFailure(debugDetail: e.toString()));
    }
  }

  @override
  Future<Result<BackgroundProfile>> duplicate(String id) async {
    final model = _box.get(id);
    if (model == null) return const Result.err(ProfileNotFoundFailure());
    final now = DateTime.now();
    final copy = model.toEntity().copyWith(
          id: 'p_${now.microsecondsSinceEpoch}',
          name: '${model.name} (copy)',
          createdDate: now,
          modifiedDate: now,
        );
    final result = await save(copy);
    return result.map((_) => copy);
  }
}
