// P0/P2 smoke test: the app boots to Home and the seeded profiles load.
import 'dart:io';

import 'package:echobug/core/di/repository_providers.dart';
import 'package:echobug/data/datasources/app_boxes.dart';
import 'package:echobug/data/models/history_model.dart';
import 'package:echobug/data/models/profile_model.dart';
import 'package:echobug/data/models/recent_file_model.dart';
import 'package:echobug/data/models/settings_model.dart';
import 'package:echobug/data/models/user_model.dart';
import 'package:echobug/presentation/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:echobug/hive_registrar.g.dart';

void main() {
  late Directory tempDir;
  late AppBoxes boxes;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('echobug_widget_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    boxes = AppBoxes(
      profiles: await Hive.openBox<ProfileModel>('w_profiles'),
      settings: await Hive.openBox<SettingsModel>('w_settings'),
      history: await Hive.openBox<HistoryModel>('w_history'),
      recentFiles: await Hive.openBox<RecentFileModel>('w_recent'),
      profileDraft: await Hive.openBox<ProfileModel>('w_draft'),
      user: await Hive.openBox<UserModel>('w_user'),
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('App boots and shows Home with bottom navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBoxesProvider.overrideWithValue(boxes)],
        child: const EchoBugApp(),
      ),
    );
    await tester.pumpAndSettle();

    // New Home (P5): file selector, profile dropdown, Apply/Preview.
    expect(find.text('No file selected'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
