import 'package:echobug/data/mappers/profile_mapper.dart';
import 'package:echobug/data/mappers/settings_mapper.dart';
import 'package:echobug/domain/entities/app_settings.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileMapper', () {
    test('round-trips through model preserving all fields', () {
      final now = DateTime(2026, 6, 15, 12, 30);
      final original = BackgroundProfile(
        id: 'p1',
        name: 'Test',
        musicFilePath: '/music/track.mp3',
        musicVolume: 33,
        noiseReduction: NoiseLevel.aggressive,
        voiceEnhancementEnabled: false,
        ducking: DuckingStrength.strong,
        fadeInSeconds: 1.5,
        fadeOutSeconds: 2.5,
        normalizationEnabled: false,
        exportFormat: ExportFormat.wav,
        createdDate: now,
        modifiedDate: now,
      );

      final restored = original.toModel().toEntity();
      expect(restored, original);
    });
  });

  group('SettingsMapper', () {
    test('round-trips including theme mode', () {
      const original = AppSettings(
        defaultExportFolder: '/out',
        defaultExportFormat: ExportFormat.aac,
        themeMode: ThemeMode.dark,
        autoOpenOutputFolder: true,
        loggingEnabled: true,
      );
      expect(original.toModel().toEntity(), original);
    });
  });
}
