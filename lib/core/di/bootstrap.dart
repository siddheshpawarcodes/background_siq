import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../data/datasources/app_boxes.dart';
import '../../data/mappers/profile_mapper.dart';
import '../../data/models/history_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/recent_file_model.dart';
import '../../data/models/settings_model.dart';
import '../../data/seed/default_profiles.dart';
import '../../hive_registrar.g.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

/// One-time application bootstrap run before `runApp` (SRS §16, P0/P1).
///
/// Initializes Hive CE, registers the generated adapters, opens the typed
/// boxes, and seeds the built-in profiles on first launch. Returns the opened
/// [AppBoxes] for injection into Riverpod.
class Bootstrap {
  Bootstrap._();

  static Future<AppBoxes> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    final boxes = AppBoxes(
      profiles: await Hive.openBox<ProfileModel>(AppConstants.profilesBox),
      settings: await Hive.openBox<SettingsModel>(AppConstants.settingsBox),
      history: await Hive.openBox<HistoryModel>(AppConstants.historyBox),
      recentFiles:
          await Hive.openBox<RecentFileModel>(AppConstants.recentFilesBox),
      profileDraft: await Hive.openBox<ProfileModel>(AppConstants.profileDraftBox),
    );

    await _seedDefaultProfiles(boxes);

    AppLogger.i('Bootstrap complete: Hive ready, ${boxes.profiles.length} profiles.');
    return boxes;
  }

  /// Seeds the six built-in profiles only when the profiles box is empty.
  static Future<void> _seedDefaultProfiles(AppBoxes boxes) async {
    if (boxes.profiles.isNotEmpty) return;
    final now = DateTime.now();
    for (final profile in defaultProfiles(now)) {
      await boxes.profiles.put(profile.id, profile.toModel());
    }
    AppLogger.i('Seeded ${boxes.profiles.length} default profiles.');
  }
}
