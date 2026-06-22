import 'dart:io';

import 'package:echobug/data/models/profile_model.dart';
import 'package:echobug/data/repositories/profile_repository_impl.dart';
import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/domain/repositories/profile_repository.dart';
import 'package:echobug/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late Box<ProfileModel> box;
  late ProfileRepository repo;

  BackgroundProfile sample(String id, String name) {
    final now = DateTime(2026, 1, 1);
    return BackgroundProfile(
      id: id,
      name: name,
      musicVolume: 20,
      noiseReduction: NoiseLevel.medium,
      ducking: DuckingStrength.medium,
      exportFormat: ExportFormat.mp3,
      createdDate: now,
      modifiedDate: now,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('echobug_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    box = await Hive.openBox<ProfileModel>('profiles_test');
    repo = ProfileRepositoryImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('profiles_test');
    await tempDir.delete(recursive: true);
  });

  test('save then getById returns the saved profile', () async {
    final p = sample('a', 'Alpha');
    final saveResult = await repo.save(p);
    expect(saveResult.isOk, isTrue);

    final fetched = await repo.getById('a');
    expect(fetched.valueOrNull, p);
  });

  test('getById returns ProfileNotFoundFailure for missing id', () async {
    final result = await repo.getById('missing');
    expect(result.isErr, isTrue);
  });

  test('getAll returns profiles sorted by name', () async {
    await repo.save(sample('b', 'Zeta'));
    await repo.save(sample('a', 'Alpha'));
    final all = await repo.getAll();
    expect(all.map((p) => p.name), ['Alpha', 'Zeta']);
  });

  test('duplicate creates a copy with new id and "(copy)" name', () async {
    await repo.save(sample('a', 'Alpha'));
    final dup = await repo.duplicate('a');
    expect(dup.isOk, isTrue);
    expect(dup.valueOrNull!.id, isNot('a'));
    expect(dup.valueOrNull!.name, 'Alpha (copy)');
    expect(await repo.getAll(), hasLength(2));
  });

  test('delete removes the profile', () async {
    await repo.save(sample('a', 'Alpha'));
    await repo.delete('a');
    expect(await repo.getAll(), isEmpty);
  });
}
