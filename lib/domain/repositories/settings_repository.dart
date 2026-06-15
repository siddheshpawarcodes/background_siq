import '../entities/app_settings.dart';

/// Persistence contract for app settings (SRS §7.3). Always returns a value —
/// defaults are supplied when nothing has been saved yet.
abstract interface class SettingsRepository {
  /// Current settings (defaults if never saved).
  Future<AppSettings> get();

  /// Emits settings on every change.
  Stream<AppSettings> watch();

  /// Persists the full settings object.
  Future<void> update(AppSettings settings);
}
