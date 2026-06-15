import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// Reads and persists app settings (SRS §7.2).
class GetSettingsUseCase {
  const GetSettingsUseCase(this._repo);
  final SettingsRepository _repo;

  Future<AppSettings> call() => _repo.get();
}

class UpdateSettingsUseCase {
  const UpdateSettingsUseCase(this._repo);
  final SettingsRepository _repo;

  Future<void> call(AppSettings settings) => _repo.update(settings);
}
