// On-device batch processing (SRS §15): multiple files, one profile.
import 'dart:io';

import 'package:background_siq/domain/entities/app_settings.dart';
import 'package:background_siq/domain/entities/audio_file_ref.dart';
import 'package:background_siq/domain/entities/background_profile.dart';
import 'package:background_siq/domain/entities/enums.dart';
import 'package:background_siq/domain/entities/history_entry.dart';
import 'package:background_siq/domain/repositories/history_repository.dart';
import 'package:background_siq/domain/repositories/settings_repository.dart';
import 'package:background_siq/domain/usecases/apply_profile_usecase.dart';
import 'package:background_siq/domain/usecases/process_batch_usecase.dart';
import 'package:background_siq/services/audio/ffmpeg_audio_processor.dart';
import 'package:background_siq/services/filesystem/file_system_service.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
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
  Future<void> update(AppSettings s) async {}
}

class _History implements HistoryRepository {
  final List<HistoryEntry> entries = [];
  @override
  Future<void> add(HistoryEntry e) async => entries.add(e);
  @override
  Future<void> clear() async {}
  @override
  Future<List<HistoryEntry>> getAll() async => entries;
  @override
  Stream<List<HistoryEntry>> watchAll() => Stream.value(entries);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('batch-processes 3 files with one profile', (tester) async {
    final tmp = await getTemporaryDirectory();
    final files = <AudioFileRef>[];
    for (var i = 0; i < 3; i++) {
      final path = p.join(tmp.path, 'batch_$i.wav');
      final s = await FFmpegKit.executeWithArguments([
        '-y', '-f', 'lavfi', '-i', 'sine=frequency=${200 + i * 40}:duration=3',
        '-ar', '44100', '-ac', '2', path,
      ]);
      expect(ReturnCode.isSuccess(await s.getReturnCode()), isTrue);
      files.add(AudioFileRef(path: path, name: 'batch_$i.wav', ext: 'wav'));
    }

    final history = _History();
    var n = 0;
    final apply = ApplyProfileUseCase(
      processor: FfmpegAudioProcessor(),
      fileSystem: const FileSystemService(),
      settings: _Settings(),
      history: history,
      idGenerator: () => 'b${n++}',
    );
    final batch = ProcessBatchUseCase(apply);

    final profile = BackgroundProfile(
      id: 'pr', name: 'Batch', musicVolume: 20,
      noiseReduction: NoiseLevel.medium, voiceEnhancementEnabled: true,
      ducking: DuckingStrength.off, fadeInSeconds: 1, fadeOutSeconds: 1,
      normalizationEnabled: true, exportFormat: ExportFormat.mp3,
      createdDate: DateTime(2026), modifiedDate: DateTime(2026));

    final last = (await batch.call(files, profile).toList()).last;

    expect(last.done, isTrue);
    expect(last.total, 3);
    expect(last.successCount, 3, reason: 'all 3 should succeed');
    for (final r in last.completed) {
      expect(File(r.outputPath!).existsSync(), isTrue);
      expect(p.basename(r.outputPath!), endsWith('_WBM.wav'));
    }
    expect(history.entries, hasLength(3));
    debugPrint('📦 BATCH: ${last.successCount}/${last.total} files processed; '
        'outputs: ${last.completed.map((r) => p.basename(r.outputPath!)).join(', ')}');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
