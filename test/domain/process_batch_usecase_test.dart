import 'package:echobug/core/errors/failures.dart';
import 'package:echobug/core/result/result.dart';
import 'package:echobug/domain/entities/app_settings.dart';
import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/domain/entities/audio_meta.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/domain/entities/history_entry.dart';
import 'package:echobug/domain/entities/process_request.dart';
import 'package:echobug/domain/ports/audio_processor_port.dart';
import 'package:echobug/domain/ports/file_system_port.dart';
import 'package:echobug/domain/repositories/history_repository.dart';
import 'package:echobug/domain/repositories/settings_repository.dart';
import 'package:echobug/domain/usecases/apply_profile_usecase.dart';
import 'package:echobug/domain/usecases/process_batch_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails for any source whose path contains "bad", otherwise completes.
class _Processor implements AudioProcessorPort {
  @override
  Stream<ProcessingProgress> process(ProcessRequest request) async* {
    yield const ProcessingProgress(stage: JobStage.mixing, progress: 0.5);
    if (request.source.path.contains('bad')) throw const FfmpegFailure();
    yield const ProcessingProgress(stage: JobStage.completed, progress: 1);
  }

  @override
  Future<Result<String>> preview(ProcessRequest r) async => Result.ok(r.outputPath);
  @override
  Future<Result<AudioMeta>> probe(String path) async =>
      const Result.ok(AudioMeta(duration: Duration(seconds: 10)));
  @override
  Future<void> cancel(String jobId) async {}
}

class _Fs implements FileSystemPort {
  @override
  Future<bool> exists(String path) async => true;
  @override
  Future<String> previewPath(String e, {String? token}) async => '/tmp/p.$e';

  @override
  Future<void> clearPreviews() async {}
  @override
  Future<Result<String>> resolveOutputPath(
          {required AudioFileRef source, String? preferredDir}) async =>
      Result.ok('/out/${source.name}_EchoBug.${source.ext}');
}

class _Settings implements SettingsRepository {
  @override
  Future<AppSettings> get() async => const AppSettings();
  @override
  Stream<AppSettings> watch() => const Stream.empty();
  @override
  Future<void> update(AppSettings s) async {}
}

class _History implements HistoryRepository {
  final List<HistoryEntry> added = [];
  @override
  Future<void> add(HistoryEntry e) async => added.add(e);
  @override
  Future<void> clear() async {}
  @override
  Future<List<HistoryEntry>> getAll() async => added;
  @override
  Stream<List<HistoryEntry>> watchAll() => Stream.value(added);
}

void main() {
  AudioFileRef ref(String name) =>
      AudioFileRef(path: '/in/$name', name: name, ext: 'wav');

  final profile = BackgroundProfile(
    id: 'p', name: 'P', musicVolume: 20,
    noiseReduction: NoiseLevel.medium, ducking: DuckingStrength.off,
    exportFormat: ExportFormat.wav,
    createdDate: DateTime(2026), modifiedDate: DateTime(2026));

  late ProcessBatchUseCase batch;
  late _History history;
  var counter = 0;

  setUp(() {
    history = _History();
    final apply = ApplyProfileUseCase(
      processor: _Processor(),
      fileSystem: _Fs(),
      settings: _Settings(),
      history: history,
      idGenerator: () => 'id${counter++}',
    );
    batch = ProcessBatchUseCase(apply);
  });

  test('processes every file and reports a per-file result', () async {
    final files = [ref('a.wav'), ref('b.wav'), ref('c.wav')];
    final last = (await batch.call(files, profile).toList()).last;

    expect(last.done, isTrue);
    expect(last.total, 3);
    expect(last.completed, hasLength(3));
    expect(last.successCount, 3);
    expect(history.added, hasLength(3));
  });

  test('a failing file does not abort the batch', () async {
    final files = [ref('a.wav'), ref('bad.wav'), ref('c.wav')];
    final last = (await batch.call(files, profile).toList()).last;

    expect(last.successCount, 2);
    expect(last.failureCount, 1);
    expect(last.completed[1].status, JobStatus.failed);
  });

  test('caps the batch at 50 files', () async {
    final files = List.generate(60, (i) => ref('f$i.wav'));
    final last = (await batch.call(files, profile).toList()).last;
    expect(last.total, 50);
    expect(last.completed, hasLength(50));
  });
}
