// On-device render verification (SRS §10, P4).
//
// Generates real input audio with FFmpeg, runs the full WBM pipeline through
// the production [FfmpegAudioProcessor], and asserts a valid output file is
// produced. This is the proof the native engine actually renders audio.
import 'dart:io';

import 'package:background_siq/domain/entities/audio_file_ref.dart';
import 'package:background_siq/domain/entities/background_profile.dart';
import 'package:background_siq/domain/entities/enums.dart';
import 'package:background_siq/domain/entities/process_request.dart';
import 'package:background_siq/services/audio/ffmpeg_audio_processor.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String voicePath;
  late String musicPath;
  final processor = FfmpegAudioProcessor();

  Future<void> generate(List<String> args) async {
    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      throw StateError('input generation failed: ${await session.getAllLogsAsString()}');
    }
  }

  BackgroundProfile profile({
    required ExportFormat format,
    String? music,
  }) {
    final now = DateTime(2026, 1, 1);
    return BackgroundProfile(
      id: 't',
      name: 'Test',
      musicFilePath: music,
      musicVolume: 20,
      noiseReduction: NoiseLevel.medium,
      voiceEnhancementEnabled: true,
      ducking: DuckingStrength.medium,
      fadeInSeconds: 1,
      fadeOutSeconds: 1,
      normalizationEnabled: true,
      exportFormat: format,
      createdDate: now,
      modifiedDate: now,
    );
  }

  Future<String> runPipeline(BackgroundProfile prof, String outPath) async {
    final request = ProcessRequest(
      jobId: 'job_${prof.exportFormat.name}',
      source: AudioFileRef(path: voicePath, name: 'voice.wav', ext: 'wav'),
      profile: prof,
      outputPath: outPath,
    );
    JobStage last = JobStage.preparing;
    await for (final progress in processor.process(request)) {
      last = progress.stage;
      if (progress.stage == JobStage.completed) break;
    }
    expect(last, JobStage.completed, reason: 'pipeline did not complete');
    return outPath;
  }

  setUpAll(() async {
    dir = await getTemporaryDirectory();
    voicePath = p.join(dir.path, 'voice.wav');
    musicPath = p.join(dir.path, 'music.wav');
    // 5s "voice" tone (mono-ish, stereo container).
    await generate([
      '-y', '-f', 'lavfi', '-i', 'sine=frequency=220:duration=5',
      '-ar', '44100', '-ac', '2', voicePath,
    ]);
    // 3s "music" tone — shorter, to exercise -stream_loop.
    await generate([
      '-y', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=3',
      '-ar', '44100', '-ac', '2', musicPath,
    ]);
  });

  testWidgets('renders full pipeline (voice + looped music + duck + fades + loudnorm) to WAV',
      (tester) async {
    final out = p.join(dir.path, 'out_WBM.wav');
    await runPipeline(profile(format: ExportFormat.wav, music: musicPath), out);

    final file = File(out);
    expect(file.existsSync(), isTrue, reason: 'output file missing');
    expect(file.lengthSync(), greaterThan(1000), reason: 'output suspiciously small');

    // Output length should track the 5s voice (amix duration=first).
    final meta = await processor.probe(out);
    expect(meta.isOk, isTrue);
    final seconds = meta.valueOrNull!.duration.inMilliseconds / 1000;
    expect(seconds, closeTo(5.0, 0.5));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('renders to MP3 320k (verifies libmp3lame / GPL build)', (tester) async {
    final out = p.join(dir.path, 'out_WBM.mp3');
    await runPipeline(profile(format: ExportFormat.mp3, music: musicPath), out);

    final file = File(out);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('voice-only render (no music) succeeds', (tester) async {
    final out = p.join(dir.path, 'voice_only_WBM.wav');
    await runPipeline(profile(format: ExportFormat.wav), out);
    expect(File(out).existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
