// On-device Profile Calibration walkthrough (Calibration design, CP8).
//
// Drives the real wizard: name -> music -> calibration sample -> calibrate,
// renders a live preview, iterates a setting, previews again, then saves —
// verifying the persisted profile carries the new calibration fields.
import 'package:echobug/core/di/bootstrap.dart';
import 'package:echobug/core/di/repository_providers.dart';
import 'package:echobug/presentation/app.dart';
import 'package:echobug/presentation/features/profile_wizard/calibration_preview_controller.dart';
import 'package:echobug/presentation/features/profile_wizard/profile_wizard_controller.dart';
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

  Future<void> pumpUntil(WidgetTester tester, bool Function() cond,
      {Duration timeout = const Duration(seconds: 90)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
      if (cond()) return;
    }
    throw StateError('Timed out');
  }

  void step(String m) => debugPrint('🎛️ CALIBRATION: $m');

  testWidgets('create + calibrate + preview + iterate + save', (tester) async {
    final boxes = await Bootstrap.init();
    final container =
        ProviderContainer(overrides: [appBoxesProvider.overrideWithValue(boxes)]);
    addTearDown(container.dispose);

    // Generate music + voice sample inputs.
    final tmp = await getTemporaryDirectory();
    final music = p.join(tmp.path, 'cal_music.wav');
    final sample = p.join(tmp.path, 'cal_voice.wav');
    for (final (path, freq) in [(music, 440), (sample, 220)]) {
      final s = await FFmpegKit.executeWithArguments([
        '-y', '-f', 'lavfi', '-i', 'sine=frequency=$freq:duration=5',
        '-ar', '44100', '-ac', '2', path,
      ]);
      expect(ReturnCode.isSuccess(await s.getReturnCode()), isTrue);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EchoBugApp()),
    );
    await tester.pumpAndSettle();

    // Profiles tab -> New Profile (opens the wizard).
    await tester.tap(find.text('Profiles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Profile'));
    await tester.pumpAndSettle();
    step('Wizard opened');

    // Step 1: name.
    final wiz = container.read(profileWizardControllerProvider(null).notifier);
    await tester.enterText(find.byType(TextField).first, 'Test Calibration');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    step('Step 1 (info) done');

    // Step 2: music (inject — bypasses system picker).
    wiz.setMusic(music);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    step('Step 2 (music) done');

    // Step 3: calibration sample.
    wiz.setCalibrationSample(sample);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    step('Step 3 (sample) done; on Calibrate');

    // Step 4: live preview.
    await tester.tap(find.widgetWithText(FilledButton, 'Preview'));
    await tester.pump();
    await pumpUntil(
        tester, () => container.read(calibrationPreviewControllerProvider).hasPreview);
    step('Preview #1 rendered + playing');

    // Iterate: change music volume, preview again.
    wiz.setVolume(35);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Preview'));
    await tester.pump();
    await pumpUntil(tester,
        () => container.read(calibrationPreviewControllerProvider).hasPreview);
    step('Preview #2 rendered after adjusting volume');

    // Save profile.
    await tester.tap(find.widgetWithText(FilledButton, 'Save profile'));
    await tester.pumpAndSettle();
    step('Saved');

    // Verify persisted profile carries the calibration fields.
    final all = await container.read(profileRepositoryProvider).getAll();
    final saved = all.firstWhere((p) => p.name == 'Test Calibration');
    expect(saved.calibrationVoiceSamplePath, sample);
    expect(saved.musicFilePath, music);
    expect(saved.musicVolume, 35);
    step('✅ Profile persisted with calibration sample + tuned settings');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
