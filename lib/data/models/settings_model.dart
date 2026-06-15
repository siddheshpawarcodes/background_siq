import 'package:hive_ce/hive.dart';

part 'settings_model.g.dart';

/// Hive persistence DTO for app settings (SRS §8.2). Singleton row.
@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  SettingsModel({
    this.defaultExportFolder,
    required this.defaultExportFormat,
    required this.themeMode,
    required this.autoOpenOutputFolder,
    required this.loggingEnabled,
  });

  @HiveField(0)
  String? defaultExportFolder;
  @HiveField(1)
  int defaultExportFormat; // ExportFormat.index
  @HiveField(2)
  int themeMode; // ThemeMode.index
  @HiveField(3)
  bool autoOpenOutputFolder;
  @HiveField(4)
  bool loggingEnabled;
}
