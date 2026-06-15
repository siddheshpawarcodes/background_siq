import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/background_profile.dart';
import '../../domain/repositories/draft_repository.dart';
import '../mappers/profile_mapper.dart';
import '../models/profile_model.dart';

/// Hive-backed [DraftRepository] storing one draft under [AppConstants.draftKey].
class DraftRepositoryImpl implements DraftRepository {
  DraftRepositoryImpl(this._box);

  final Box<ProfileModel> _box;

  @override
  BackgroundProfile? load() => _box.get(AppConstants.draftKey)?.toEntity();

  @override
  Future<void> save(BackgroundProfile draft) =>
      _box.put(AppConstants.draftKey, draft.toModel());

  @override
  Future<void> clear() => _box.delete(AppConstants.draftKey);
}
