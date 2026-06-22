// Full on-device UI walkthrough (SRS §11, §12).
//
// Boots the REAL app with real Hive storage and drives it through every screen
// on the device: Home -> Apply -> Processing -> result, then History, Profiles,
// Profile Editor, and Settings. The file-picker step is bypassed by injecting a
// generated voice file (the system picker cannot be automated), which is exactly
// the AudioFileRef the picker would have produced.
import 'package:echobug/core/di/bootstrap.dart';
import 'package:echobug/core/di/repository_providers.dart';
import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/presentation/app.dart';
import 'package:echobug/presentation/features/home/home_controller.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps frames until [finder] matches or [timeout] elapses.
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw StateError('Timed out waiting for: $finder');
  }

  void step(String msg) => debugPrint('🚶 WALKTHROUGH: $msg');

  testWidgets('drives every screen on device', (tester) async {
    // --- Boot the real app ---
    final boxes = await Bootstrap.init();
    final container =
        ProviderContainer(overrides: [appBoxesProvider.overrideWithValue(boxes)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EchoBugApp()),
    );
    await tester.pumpAndSettle();
    step('Home loaded');
    expect(find.text('EchoBug'), findsOneWidget);
    expect(find.text('No file selected'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);

    // Seeded profiles available.
    await pumpUntil(tester, find.text('Background music profile'));
    final profiles = await container.read(profileRepositoryProvider).getAll();
    expect(profiles.length, greaterThanOrEqualTo(6));
    step('Profiles loaded: ${profiles.map((e) => e.name).join(', ')}');

    // --- Inject a generated voice file (stand-in for the system picker) ---
    final tmp = await getTemporaryDirectory();
    final voicePath = p.join(tmp.path, 'demo.wav');
    final gen = await FFmpegKit.executeWithArguments([
      '-y', '-f', 'lavfi', '-i', 'sine=frequency=220:duration=4',
      '-ar', '44100', '-ac', '2', voicePath,
    ]);
    expect(ReturnCode.isSuccess(await gen.getReturnCode()), isTrue);

    container.read(homeControllerProvider.notifier).selectFileRef(
          AudioFileRef(path: voicePath, name: 'demo.wav', ext: 'wav'),
        );
    container.read(homeControllerProvider.notifier).selectProfile(profiles.first.id);
    await tester.pumpAndSettle();
    // Appears in the file-selector card (and now also the recent-files list).
    expect(find.text('demo.wav'), findsWidgets);
    step('File + profile selected (${profiles.first.name}); Apply enabled');

    // --- Apply -> Processing -> result ---
    await tester.tap(find.text('Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Processing'), findsOneWidget);
    step('Processing screen shown; rendering on device...');

    await pumpUntil(tester, find.text('Completed'));
    expect(find.text('Open file'), findsOneWidget);
    step('Render COMPLETED; success card shown');

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // --- History tab ---
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.textContaining('demo_EchoBug'));
    step('History shows the new entry (demo_EchoBug.wav)');

    // --- Profiles tab + open editor ---
    await tester.tap(find.text('Profiles'));
    await tester.pumpAndSettle();
    expect(find.text('Corporate'), findsOneWidget);
    step('Profiles list shown');

    await tester.tap(find.text('Corporate'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Profile name'), findsOneWidget);
    expect(find.text('Noise reduction'), findsOneWidget);
    expect(find.text('Output format'), findsOneWidget);
    step('Profile Editor opened with all fields');

    await tester.pageBack();
    await tester.pumpAndSettle();

    // --- Settings tab + live theme switch ---
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Clear cache'), findsOneWidget);
    expect(find.text('Reset app'), findsOneWidget);
    step('Settings shown');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final dark = await container.read(settingsRepositoryProvider).get();
    expect(dark.themeMode, ThemeMode.dark);
    step('Theme switched to Dark (persisted)');

    step('✅ Walkthrough complete — all 6 screens exercised on device');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
