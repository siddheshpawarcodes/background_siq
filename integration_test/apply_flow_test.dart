// On-device end-to-end Apply flow (SRS §7.2, P5).
//
// Exercises the real ApplyProfileUseCase with the production FfmpegAudioProcessor
// and FileSystemService: generates a voice file, runs Apply, and asserts a
// real `_EchoBug` output file is written to the resolved path and history recorded.
import 'dart:io';

import 'package:echobug/domain/entities/app_settings.dart';
import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/domain/entities/history_entry.dart';
import 'package:echobug/domain/repositories/history_repository.dart';
import 'package:echobug/domain/repositories/settings_repository.dart';
import 'package:echobug/domain/usecases/apply_profile_usecase.dart';
import 'package:echobug/services/audio/ffmpeg_audio_processor.dart';
import 'package:echobug/services/filesystem/file_system_service.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class _Settings implements SettingsRepository {
  @override
  Future<AppSettings> get() async => const AppSettings();
  @override
  Stream<AppSettings> watch() => const Stream.empty();
  @override
  Future<void> update(AppSettings settings) async {}
}

class _History implements HistoryRepository {
  final List<HistoryEntry> entries = [];
  @override
  Future<void> add(HistoryEntry entry) async => entries.add(entry);
  @override
  Future<void> clear() async {}
  @override
  Future<List<HistoryEntry>> getAll() async => entries;
  @override
  Stream<List<HistoryEntry>> watchAll() => Stream.value(entries);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Apply writes a real _EchoBug file and records success history',
      (tester) async {
    final tmp = await getTemporaryDirectory();
    final voicePath = p.join(tmp.path, 'meeting.wav');

    // Generate a 4s voice tone.
    final gen = await FFmpegKit.executeWithArguments([
      '-y', '-f', 'lavfi', '-i', 'sine=frequency=200:duration=4',
      '-ar', '44100', '-ac', '2', voicePath,
    ]);
    expect(ReturnCode.isSuccess(await gen.getReturnCode()), isTrue);

    final history = _History();
    var counter = 0;
    final useCase = ApplyProfileUseCase(
      processor: FfmpegAudioProcessor(),
      fileSystem: const FileSystemService(),
      settings: _Settings(),
      history: history,
      idGenerator: () => 'job${counter++}',
    );

    final source = AudioFileRef(path: voicePath, name: 'meeting.wav', ext: 'wav');
    final profile = BackgroundProfile(
      id: 'pr',
      name: 'Corporate',
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

    final jobs = await useCase.call(source, profile).toList();
    final last = jobs.last;

    expect(last.stage, JobStage.completed, reason: last.errorMessage ?? '');
    expect(last.outputPath, isNotNull);
    // Mirror-source extension: meeting.wav -> meeting_EchoBug.wav
    expect(p.basename(last.outputPath!), 'meeting_EchoBug.wav');
    expect(File(last.outputPath!).existsSync(), isTrue);
    expect(File(last.outputPath!).lengthSync(), greaterThan(1000));

    expect(history.entries.single.status, JobStatus.success);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
