import 'dart:async';

import 'package:echobug/core/errors/failures.dart';
import 'package:echobug/core/result/result.dart';
import 'package:echobug/domain/entities/app_settings.dart';
import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/domain/entities/audio_meta.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/dataset_batch_config.dart';
import 'package:echobug/domain/entities/dataset_batch_progress.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/domain/entities/history_entry.dart';
import 'package:echobug/domain/entities/process_request.dart';
import 'package:echobug/domain/entities/suffix_profile.dart';
import 'package:echobug/domain/ports/audio_processor_port.dart';
import 'package:echobug/domain/ports/file_system_port.dart';
import 'package:echobug/domain/ports/media_store_port.dart';
import 'package:echobug/domain/repositories/history_repository.dart';
import 'package:echobug/domain/repositories/profile_repository.dart';
import 'package:echobug/domain/repositories/settings_repository.dart';
import 'package:echobug/domain/usecases/apply_profile_usecase.dart';
import 'package:echobug/domain/usecases/process_dataset_usecase.dart';
import 'package:echobug/services/dataset/dataset_batch_cancellation_token.dart';
import 'package:echobug/services/dataset/dataset_file_scanner.dart';
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

/// exists() is false for any path containing "missing".
class _Fs implements FileSystemPort {
  @override
  Future<bool> exists(String path) async => !path.contains('missing');
  @override
  Future<String> previewPath(String e) async => '/tmp/p.$e';
  @override
  Future<Result<String>> resolveOutputPath(
          {required AudioFileRef source, String? preferredDir}) async =>
      Result.ok('${preferredDir ?? '/out'}/${source.name}_EchoBug.${source.ext}');
}

/// Records publish calls; returns null so the use case keeps the staging file
/// (no real filesystem side effects in tests).
class _MediaStore implements MediaStorePort {
  final List<String> published = [];
  @override
  Future<String?> publishToMusic({
    required String sourcePath,
    required String relativeDir,
    required String displayName,
    required String mimeType,
  }) async {
    published.add('$relativeDir/$displayName');
    return null;
  }
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

class _Profiles implements ProfileRepository {
  _Profiles(this._profile);
  final BackgroundProfile? _profile;

  @override
  Future<Result<BackgroundProfile>> getById(String id) async =>
      _profile == null
          ? const Result.err(ProfileNotFoundFailure())
          : Result.ok(_profile);

  @override
  BackgroundProfile? getByIdSync(String id) => _profile;
  @override
  Future<List<BackgroundProfile>> getAll() async =>
      _profile == null ? [] : [_profile];
  @override
  Stream<List<BackgroundProfile>> watchAll() =>
      Stream.value(_profile == null ? [] : [_profile]);
  @override
  Future<Result<void>> save(BackgroundProfile p) async => const Result.ok(null);
  @override
  Future<Result<void>> delete(String id) async => const Result.ok(null);
  @override
  Future<Result<BackgroundProfile>> duplicate(String id) async =>
      const Result.err(ProfileNotFoundFailure());
}

/// Resolves profiles from a fixed id→profile map (for per-suffix routing).
class _MultiProfiles implements ProfileRepository {
  _MultiProfiles(this._byId);
  final Map<String, BackgroundProfile> _byId;

  @override
  Future<Result<BackgroundProfile>> getById(String id) async {
    final p = _byId[id];
    return p == null
        ? const Result.err(ProfileNotFoundFailure())
        : Result.ok(p);
  }

  @override
  BackgroundProfile? getByIdSync(String id) => _byId[id];
  @override
  Future<List<BackgroundProfile>> getAll() async => _byId.values.toList();
  @override
  Stream<List<BackgroundProfile>> watchAll() => Stream.value(_byId.values.toList());
  @override
  Future<Result<void>> save(BackgroundProfile p) async => const Result.ok(null);
  @override
  Future<Result<void>> delete(String id) async => const Result.ok(null);
  @override
  Future<Result<BackgroundProfile>> duplicate(String id) async =>
      const Result.err(ProfileNotFoundFailure());
}

/// Records which profile each source path was processed with, so a test can
/// assert per-suffix routing. Always completes successfully.
class _RecordingProcessor implements AudioProcessorPort {
  final Map<String, String> profileIdByPath = {};
  @override
  Stream<ProcessingProgress> process(ProcessRequest request) async* {
    profileIdByPath[request.source.path] = request.profile.id;
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

void main() {
  final profile = BackgroundProfile(
    id: 'p',
    name: 'P',
    musicVolume: 20,
    noiseReduction: NoiseLevel.medium,
    ducking: DuckingStrength.off,
    exportFormat: ExportFormat.wav,
    createdDate: DateTime(2026),
    modifiedDate: DateTime(2026),
  );

  const config = DatasetBatchConfig(
    rootFolder: '/data',
    suffixProfiles: [SuffixProfile(suffix: '_eng', profileId: 'p')],
  );

  late _History history;
  var counter = 0;

  ProcessDatasetUseCase build({BackgroundProfile? withProfile}) {
    history = _History();
    final apply = ApplyProfileUseCase(
      processor: _Processor(),
      fileSystem: _Fs(),
      settings: _Settings(),
      history: history,
      idGenerator: () => 'id${counter++}',
    );
    return ProcessDatasetUseCase(
      buildApply: (_) async => apply,
      profiles: _Profiles(withProfile),
      scanner: const DatasetFileScanner(),
      fileSystem: _Fs(),
      mediaStore: _MediaStore(),
    );
  }

  test('processes every matching file and reports a summary', () async {
    final usecase = build(withProfile: profile);
    final last = (await usecase.call(
      config,
      onlyPaths: ['/data/A/a_eng.m4a', '/data/B/b_eng.m4a', '/data/C/c_eng.m4a'],
    ).toList())
        .last;

    expect(last.completed, isTrue);
    expect(last.totalFiles, 3);
    expect(last.processedFiles, 3);
    expect(last.successfulFiles, 3);
    expect(last.failedFiles, 0);
    expect(last.overall, 1.0);
    expect(history.added, hasLength(3));
  });

  test('routes each suffix to its own profile (different music per suffix)',
      () async {
    final profileA = profile.copyWith(id: 'a', name: 'A');
    final profileB = profile.copyWith(id: 'b', name: 'B');
    final recorder = _RecordingProcessor();
    final apply = ApplyProfileUseCase(
      processor: recorder,
      fileSystem: _Fs(),
      settings: _Settings(),
      history: _History(),
      idGenerator: () => 'id${counter++}',
    );
    final usecase = ProcessDatasetUseCase(
      buildApply: (_) async => apply,
      profiles: _MultiProfiles({'a': profileA, 'b': profileB}),
      scanner: const DatasetFileScanner(),
      fileSystem: _Fs(),
      mediaStore: _MediaStore(),
    );
    const cfg = DatasetBatchConfig(
      rootFolder: '/data',
      suffixProfiles: [
        SuffixProfile(suffix: '_eng', profileId: 'a'),
        SuffixProfile(suffix: '_hin', profileId: 'b'),
      ],
    );

    final last = (await usecase.call(
      cfg,
      onlyPaths: ['/data/F/x_eng.m4a', '/data/F/x_hin.m4a'],
    ).toList())
        .last;

    expect(last.successfulFiles, 2);
    expect(recorder.profileIdByPath['/data/F/x_eng.m4a'], 'a');
    expect(recorder.profileIdByPath['/data/F/x_hin.m4a'], 'b');
  });

  test('fails only the files whose suffix profile is missing', () async {
    final profileA = profile.copyWith(id: 'a', name: 'A');
    final apply = ApplyProfileUseCase(
      processor: _Processor(),
      fileSystem: _Fs(),
      settings: _Settings(),
      history: _History(),
      idGenerator: () => 'id${counter++}',
    );
    final usecase = ProcessDatasetUseCase(
      buildApply: (_) async => apply,
      // '_hin' maps to 'b' which does not resolve.
      profiles: _MultiProfiles({'a': profileA}),
      scanner: const DatasetFileScanner(),
      fileSystem: _Fs(),
      mediaStore: _MediaStore(),
    );
    const cfg = DatasetBatchConfig(
      rootFolder: '/data',
      suffixProfiles: [
        SuffixProfile(suffix: '_eng', profileId: 'a'),
        SuffixProfile(suffix: '_hin', profileId: 'b'),
      ],
    );

    final last = (await usecase.call(
      cfg,
      onlyPaths: ['/data/x_eng.m4a', '/data/x_hin.m4a'],
    ).toList())
        .last;

    expect(last.successfulFiles, 1);
    expect(last.failedFiles, 1);
    expect(last.failures.single.filePath, '/data/x_hin.m4a');
  });

  test('a failing file does not abort the rest of the dataset', () async {
    final usecase = build(withProfile: profile);
    final last = (await usecase.call(
      config,
      onlyPaths: ['/data/a_eng.m4a', '/data/bad_eng.m4a', '/data/c_eng.m4a'],
    ).toList())
        .last;

    expect(last.successfulFiles, 2);
    expect(last.failedFiles, 1);
    expect(last.failures, hasLength(1));
    expect(last.failures.first.filePath, '/data/bad_eng.m4a');
    expect(last.processedFiles, 3);
  });

  test('skips files that vanished between discovery and processing', () async {
    final usecase = build(withProfile: profile);
    final last = (await usecase.call(
      config,
      onlyPaths: ['/data/a_eng.m4a', '/data/missing_eng.m4a'],
    ).toList())
        .last;

    expect(last.successfulFiles, 1);
    expect(last.skippedFiles, 1);
    expect(last.failedFiles, 0);
    expect(last.processedFiles, 2);
  });

  test('cancellation stops after the current file finishes', () async {
    final usecase = build(withProfile: profile);
    final token = DatasetBatchCancellationToken();
    final done = Completer<DatasetBatchProgress>();
    DatasetBatchProgress? lastEvent;

    late StreamSubscription<DatasetBatchProgress> sub;
    sub = usecase
        .call(
      config,
      cancelToken: token,
      onlyPaths: ['/data/a_eng.m4a', '/data/b_eng.m4a', '/data/c_eng.m4a'],
    )
        .listen((p) {
      lastEvent = p;
      // Cancel midway through the first file.
      if (p.currentFileProgress > 0 && !token.isCancelled) token.cancel();
    }, onDone: () => done.complete(lastEvent!));

    final last = await done.future;
    await sub.cancel();

    expect(last.cancelled, isTrue);
    expect(last.completed, isTrue);
    expect(last.processedFiles, 1);
    expect(last.successfulFiles, 1);
  });

  test('retry processes only the supplied paths', () async {
    final usecase = build(withProfile: profile);
    final last = (await usecase.call(
      config,
      onlyPaths: ['/data/bad_eng.m4a'],
    ).toList())
        .last;

    expect(last.totalFiles, 1);
    expect(last.failedFiles, 1);
  });

  test('reports a failure when the profile is missing', () async {
    final usecase = build(); // no profile
    final last = (await usecase.call(
      config,
      onlyPaths: ['/data/a_eng.m4a'],
    ).toList())
        .last;

    expect(last.completed, isTrue);
    expect(last.failures, hasLength(1));
    expect(last.processedFiles, 0);
  });

  test('completes cleanly on an empty dataset', () async {
    final usecase = build(withProfile: profile);
    final last = (await usecase.call(config, onlyPaths: const []).toList()).last;

    expect(last.completed, isTrue);
    expect(last.totalFiles, 0);
  });
}
