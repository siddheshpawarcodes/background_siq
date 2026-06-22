import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../data/datasources/app_boxes.dart';
import '../../data/mappers/profile_mapper.dart';
import '../../data/seed/default_profiles.dart';

/// Cache and reset operations for the Settings screen (SRS §11.6).
class MaintenanceService {
  const MaintenanceService(this._boxes);

  final AppBoxes _boxes;

  /// Deletes temporary preview files. Returns the number of files removed.
  Future<int> clearCache() async {
    final tmp = await getTemporaryDirectory();
    var removed = 0;
    if (await tmp.exists()) {
      await for (final entity in tmp.list()) {
        if (entity is File && p.basename(entity.path).startsWith('echobug_preview')) {
          await entity.delete();
          removed++;
        }
      }
    }
    AppLogger.i('Cleared $removed cached preview file(s).');
    return removed;
  }

  /// Clears all stored data and restores the built-in profiles.
  Future<void> resetApp() async {
    await Future.wait([
      _boxes.profiles.clear(),
      _boxes.settings.clear(),
      _boxes.history.clear(),
      _boxes.recentFiles.clear(),
      _boxes.user.clear(),
    ]);
    final now = DateTime.now();
    for (final profile in defaultProfiles(now)) {
      await _boxes.profiles.put(profile.id, profile.toModel());
    }
    AppLogger.i('App reset; reseeded ${_boxes.profiles.length} default profiles.');
  }
}
