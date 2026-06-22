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
import 'package:flutter_test/flutter_test.dart';

class _FakeProcessor implements AudioProcessorPort {
  bool fail = false;
  @override
  Stream<ProcessingProgress> process(ProcessRequest request) async* {
    yield const ProcessingProgress(stage: JobStage.mixing, progress: 0.5);
    if (fail) throw const FfmpegFailureStub();
    yield const ProcessingProgress(stage: JobStage.completed, progress: 1);
  }

  @override
  Future<Result<String>> preview(ProcessRequest request) async => Result.ok(request.outputPath);
  @override
  Future<Result<AudioMeta>> probe(String path) async =>
      const Result.ok(AudioMeta(duration: Duration(seconds: 60)));
  @override
  Future<void> cancel(String jobId) async {}
}

class FfmpegFailureStub implements Exception {
  const FfmpegFailureStub();
}

class _FakeFs implements FileSystemPort {
  bool fileExists = true;
  @override
  Future<bool> exists(String path) async => fileExists;
  @override
  Future<String> previewPath(String extension) async => '/tmp/preview.$extension';
  @override
  Future<Result<String>> resolveOutputPath(
          {required AudioFileRef source, String? preferredDir}) async =>
      const Result.ok('/out/meeting_EchoBug.mp3');
}

class _FakeSettings implements SettingsRepository {
  @override
  Future<AppSettings> get() async => const AppSettings();
  @override
  Stream<AppSettings> watch() => const Stream.empty();
  @override
  Future<void> update(AppSettings settings) async {}
}

class _FakeHistory implements HistoryRepository {
  final List<HistoryEntry> added = [];
  @override
  Future<void> add(HistoryEntry entry) async => added.add(entry);
  @override
  Future<void> clear() async {}
  @override
  Future<List<HistoryEntry>> getAll() async => added;
  @override
  Stream<List<HistoryEntry>> watchAll() => Stream.value(added);
}

void main() {
  final source = const AudioFileRef(path: '/in/meeting.mp3', name: 'meeting.mp3', ext: 'mp3');
  final profile = BackgroundProfile(
    id: 'p',
    name: 'Corporate',
    musicVolume: 20,
    noiseReduction: NoiseLevel.medium,
    ducking: DuckingStrength.medium,
    exportFormat: ExportFormat.mp3,
    createdDate: DateTime(2026),
    modifiedDate: DateTime(2026),
  );

  late _FakeProcessor processor;
  late _FakeHistory history;
  late ApplyProfileUseCase useCase;
  var idCounter = 0;

  setUp(() {
    processor = _FakeProcessor();
    history = _FakeHistory();
    useCase = ApplyProfileUseCase(
      processor: processor,
      fileSystem: _FakeFs(),
      settings: _FakeSettings(),
      history: history,
      idGenerator: () => 'id${idCounter++}',
    );
  });

  test('emits completed with output path and records success history', () async {
    final jobs = await useCase.call(source, profile).toList();
    expect(jobs.last.stage, JobStage.completed);
    expect(jobs.last.outputPath, '/out/meeting_EchoBug.mp3');
    expect(history.added.single.status, JobStatus.success);
  });

  test('rejects unsupported format before processing', () async {
    final bad = const AudioFileRef(path: '/in/x.txt', name: 'x.txt', ext: 'txt');
    final jobs = await useCase.call(bad, profile).toList();
    expect(jobs.single.stage, JobStage.failed);
    expect(history.added, isEmpty);
  });

  test('records failed history when the engine errors', () async {
    processor.fail = true;
    final jobs = await useCase.call(source, profile).toList();
    expect(jobs.last.stage, JobStage.failed);
    expect(history.added.single.status, JobStatus.failed);
  });
}
