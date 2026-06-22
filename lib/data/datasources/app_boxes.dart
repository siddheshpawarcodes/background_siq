import 'package:hive_ce/hive.dart';

import '../models/history_model.dart';
import '../models/profile_model.dart';
import '../models/recent_file_model.dart';
import '../models/settings_model.dart';
import '../models/user_model.dart';

/// Holds the opened Hive boxes (SRS §8.1). Opened once during bootstrap and
/// injected into repositories via Riverpod.
class AppBoxes {
  const AppBoxes({
    required this.profiles,
    required this.settings,
    required this.history,
    required this.recentFiles,
    required this.profileDraft,
    required this.user,
  });

  final Box<ProfileModel> profiles;
  final Box<SettingsModel> settings;
  final Box<HistoryModel> history;
  final Box<RecentFileModel> recentFiles;
  final Box<ProfileModel> profileDraft;
  final Box<UserModel> user;
}
