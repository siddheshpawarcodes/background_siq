import 'package:flutter/material.dart' show ThemeMode;
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'app_settings.freezed.dart';

/// User preferences persisted locally (SRS §7.1, §11.6).
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    String? defaultExportFolder,
    @Default(ExportFormat.mp3) ExportFormat defaultExportFormat,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool autoOpenOutputFolder,
    @Default(false) bool loggingEnabled,
  }) = _AppSettings;
}
