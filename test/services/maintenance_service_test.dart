import 'dart:io';

import 'package:echobug/data/datasources/app_boxes.dart';
import 'package:echobug/data/models/history_model.dart';
import 'package:echobug/data/models/profile_model.dart';
import 'package:echobug/data/models/recent_file_model.dart';
import 'package:echobug/data/models/settings_model.dart';
import 'package:echobug/data/models/user_model.dart';
import 'package:echobug/hive_registrar.g.dart';
import 'package:echobug/services/maintenance/maintenance_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late AppBoxes boxes;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('echobug_maint_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    boxes = AppBoxes(
      profiles: await Hive.openBox<ProfileModel>('m_profiles'),
      settings: await Hive.openBox<SettingsModel>('m_settings'),
      history: await Hive.openBox<HistoryModel>('m_history'),
      recentFiles: await Hive.openBox<RecentFileModel>('m_recent'),
      profileDraft: await Hive.openBox<ProfileModel>('m_draft'),
      user: await Hive.openBox<UserModel>('m_user'),
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('resetApp clears history and reseeds the 6 default profiles', () async {
    // Seed some junk data.
    await boxes.history.put('h', HistoryModel(
      id: 'h', sourcePath: 's', outputPath: 'o', date: DateTime(2026),
      profileName: 'x', processingMillis: 1, status: 0));
    await boxes.profiles.put('custom', ProfileModel(
      id: 'custom', name: 'Custom', musicVolume: 50, noiseReductionLevel: 0,
      voiceEnhancementEnabled: true, duckingStrength: 0, fadeInSeconds: 0,
      fadeOutSeconds: 0, normalizationEnabled: true, exportFormat: 0,
      createdDate: DateTime(2026), modifiedDate: DateTime(2026)));

    await MaintenanceService(boxes).resetApp();

    expect(boxes.history.isEmpty, isTrue);
    expect(boxes.profiles.length, 6);
    expect(boxes.profiles.containsKey('custom'), isFalse);
    expect(boxes.profiles.containsKey('seed_corporate'), isTrue);
  });
}
