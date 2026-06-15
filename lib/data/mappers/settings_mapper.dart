import 'package:flutter/material.dart' show ThemeMode;

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/enums.dart';
import '../models/settings_model.dart';
import 'enum_mapper.dart';

/// Maps [SettingsModel] (Hive) ⇄ [AppSettings] (domain).
extension SettingsModelMapper on SettingsModel {
  AppSettings toEntity() => AppSettings(
        defaultExportFolder: defaultExportFolder,
        defaultExportFormat: ExportFormat.values.fromIndex(defaultExportFormat),
        themeMode: ThemeMode.values.fromIndex(themeMode, fallback: ThemeMode.system),
        autoOpenOutputFolder: autoOpenOutputFolder,
        loggingEnabled: loggingEnabled,
      );
}

extension AppSettingsMapper on AppSettings {
  SettingsModel toModel() => SettingsModel(
        defaultExportFolder: defaultExportFolder,
        defaultExportFormat: defaultExportFormat.index,
        themeMode: themeMode.index,
        autoOpenOutputFolder: autoOpenOutputFolder,
        loggingEnabled: loggingEnabled,
      );
}
