// On-device verification of m4a (AAC) as both input and output container.
import 'dart:io';

import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/domain/entities/process_request.dart';
import 'package:echobug/services/audio/ffmpeg_audio_processor.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final processor = FfmpegAudioProcessor();
  late Directory dir;

  Future<void> generate(List<String> args) async {
    final s = await FFmpegKit.executeWithArguments(args);
    expect(ReturnCode.isSuccess(await s.getReturnCode()), isTrue,
        reason: await s.getAllLogsAsString());
  }

  BackgroundProfile prof() => BackgroundProfile(
        id: 't',
        name: 'T',
        musicVolume: 20,
        noiseReduction: NoiseLevel.medium,
        voiceEnhancementEnabled: true,
        ducking: DuckingStrength.off,
        fadeInSeconds: 1,
        fadeOutSeconds: 1,
        normalizationEnabled: true,
        exportFormat: ExportFormat.aac,
        createdDate: DateTime(2026),
        modifiedDate: DateTime(2026),
      );

  Future<void> run(AudioFileRef source, String outPath) async {
    final req = ProcessRequest(
      jobId: 'j', source: source, profile: prof(), outputPath: outPath);
    JobStage last = JobStage.preparing;
    await for (final pr in processor.process(req)) {
      last = pr.stage;
      if (last == JobStage.completed) break;
    }
    expect(last, JobStage.completed);
  }

  setUpAll(() async => dir = await getTemporaryDirectory());

  testWidgets('renders pipeline OUTPUT to .m4a (AAC encode in MP4 container)',
      (tester) async {
    final voice = p.join(dir.path, 'v.wav');
    await generate(['-y', '-f', 'lavfi', '-i', 'sine=frequency=220:duration=4',
      '-ar', '44100', '-ac', '2', voice]);

    final out = p.join(dir.path, 'voice_EchoBug.m4a');
    await run(AudioFileRef(path: voice, name: 'v.wav', ext: 'wav'), out);

    expect(File(out).existsSync(), isTrue);
    expect(File(out).lengthSync(), greaterThan(1000));
    final meta = await processor.probe(out);
    expect(meta.isOk, isTrue);
    expect(meta.valueOrNull!.duration.inMilliseconds / 1000, closeTo(4.0, 0.6));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('accepts .m4a as INPUT and processes it', (tester) async {
    // Make a real m4a source first.
    final src = p.join(dir.path, 'in.m4a');
    await generate(['-y', '-f', 'lavfi', '-i', 'sine=frequency=300:duration=4',
      '-c:a', 'aac', '-b:a', '128k', src]);

    final out = p.join(dir.path, 'in_EchoBug.m4a');
    await run(AudioFileRef(path: src, name: 'in.m4a', ext: 'm4a'), out);

    expect(File(out).existsSync(), isTrue);
    expect(File(out).lengthSync(), greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
