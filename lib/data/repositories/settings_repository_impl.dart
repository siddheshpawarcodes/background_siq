import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../mappers/settings_mapper.dart';
import '../models/settings_model.dart';

/// Hive-backed implementation of [SettingsRepository] (SRS §7.3).
/// Returns sensible defaults when nothing has been persisted yet.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._box);

  final Box<SettingsModel> _box;

  static const _defaults = AppSettings();

  AppSettings _read() => _box.get(AppConstants.settingsKey)?.toEntity() ?? _defaults;

  @override
  Future<AppSettings> get() async => _read();

  @override
  Stream<AppSettings> watch() async* {
    yield _read();
    yield* _box.watch().map((_) => _read());
  }

  @override
  Future<void> update(AppSettings settings) async {
    await _box.put(AppConstants.settingsKey, settings.toModel());
  }
}
