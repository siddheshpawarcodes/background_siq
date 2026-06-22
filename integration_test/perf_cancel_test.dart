// On-device hardening (SRS §NFR-2, P9): long-file performance + cancellation.
import 'dart:async';

import 'package:echobug/core/errors/failures.dart';
import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/domain/entities/process_request.dart';
import 'package:echobug/services/audio/ffmpeg_audio_processor.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final processor = FfmpegAudioProcessor();
  late String dirPath;

  Future<String> generateVoice(String name, int seconds) async {
    final path = p.join(dirPath, name);
    final s = await FFmpegKit.executeWithArguments([
      '-y', '-f', 'lavfi', '-i', 'sine=frequency=220:duration=$seconds',
      '-ar', '44100', '-ac', '2', path,
    ]);
    expect(ReturnCode.isSuccess(await s.getReturnCode()), isTrue);
    return path;
  }

  BackgroundProfile profile() => BackgroundProfile(
        id: 'h',
        name: 'H',
        musicVolume: 20,
        noiseReduction: NoiseLevel.medium,
        voiceEnhancementEnabled: true,
        ducking: DuckingStrength.off,
        fadeInSeconds: 1,
        fadeOutSeconds: 1,
        normalizationEnabled: true,
        exportFormat: ExportFormat.mp3,
        createdDate: DateTime(2026),
        modifiedDate: DateTime(2026),
      );

  setUpAll(() async => dirPath = (await getTemporaryDirectory()).path);

  testWidgets('processes a long (3 min) file without crashing', (tester) async {
    final voice = await generateVoice('long.wav', 180);
    final out = p.join(dirPath, 'long_EchoBug.mp3');
    final request = ProcessRequest(
      jobId: 'perf', source: AudioFileRef(path: voice, name: 'long.wav', ext: 'wav'),
      profile: profile(), outputPath: out);

    final sw = Stopwatch()..start();
    JobStage last = JobStage.preparing;
    var maxProgress = 0.0;
    await for (final pr in processor.process(request)) {
      last = pr.stage;
      maxProgress = pr.progress > maxProgress ? pr.progress : maxProgress;
      if (last == JobStage.completed) break;
    }
    sw.stop();
    expect(last, JobStage.completed);
    expect(maxProgress, greaterThan(0.0)); // progress actually advanced
    debugPrint('⏱️ PERF: 180s audio processed in ${sw.elapsedMilliseconds}ms '
        '(${(180000 / sw.elapsedMilliseconds).toStringAsFixed(1)}x realtime)');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('cancellation stops a running render', (tester) async {
    final voice = await generateVoice('cancel.wav', 120);
    final out = p.join(dirPath, 'cancel_EchoBug.mp3');
    final request = ProcessRequest(
      jobId: 'cancel-job', source: AudioFileRef(path: voice, name: 'cancel.wav', ext: 'wav'),
      profile: profile(), outputPath: out);

    final completer = Completer<Object?>();
    var cancelled = false;
    final sub = processor.process(request).listen(
      (pr) async {
        // Once rendering has actually started, cancel it.
        if (pr.progress > 0 && !cancelled) {
          cancelled = true;
          await processor.cancel('cancel-job');
        }
        if (pr.stage == JobStage.completed && !completer.isCompleted) {
          completer.complete('completed'); // unexpected
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.complete(e);
      },
    );

    final outcome = await completer.future.timeout(const Duration(minutes: 2));
    await sub.cancel();
    expect(cancelled, isTrue, reason: 'never reached a running state to cancel');
    expect(outcome, isA<CancelledFailure>(),
        reason: 'expected a cancellation, got: $outcome');
    debugPrint('🛑 CANCEL: render cancelled mid-flight as expected');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
