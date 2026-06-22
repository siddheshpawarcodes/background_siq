// Data-layer test for the account feature. Runs on the real event loop (plain
// `test`, not `testWidgets`), so awaited Hive writes complete normally —
// exercising AuthRepositoryImpl + StubAuthService end to end: sign in, edit
// profile, re-sign-in (edits preserved), and sign out.
import 'dart:io';

import 'package:echobug/core/constants/app_constants.dart';
import 'package:echobug/data/models/user_model.dart';
import 'package:echobug/data/repositories/auth_repository_impl.dart';
import 'package:echobug/domain/entities/auth_user.dart';
import 'package:echobug/hive_registrar.g.dart';
import 'package:echobug/services/auth/stub_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late Box<UserModel> box;
  late AuthRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('echobug_authrepo_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapters();
    box = await Hive.openBox<UserModel>('ar_user');
    repo = AuthRepositoryImpl(box: box, service: const StubAuthService());
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('starts signed out', () {
    expect(repo.current, isNull);
  });

  test('signInWithGoogle persists the account and emits it on the stream', () async {
    final emissions = <AuthUser?>[];
    final sub = repo.watch().listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 20)); // let watch subscribe

    final result = await repo.signInWithGoogle();

    expect(result.isOk, isTrue);
    final user = result.valueOrNull!;
    expect(user.email, 'demo.user@gmail.com');
    expect(user.googleDisplayName, 'Demo User');
    expect(repo.current?.email, 'demo.user@gmail.com');
    expect(box.get(AppConstants.userKey), isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 50)); // let the stream deliver
    expect(emissions.last?.email, 'demo.user@gmail.com');
    await sub.cancel();
  });

  test('updateProfile stores the editable fields and resolves effectiveName', () async {
    await repo.signInWithGoogle();
    final user = repo.current!;

    await repo.updateProfile(user.copyWith(
      displayNameOverride: 'Jimmy Patel',
      phone: '+1 555 0100',
      company: 'Windowmaker',
      role: 'Estimator',
    ));

    final saved = repo.current!;
    expect(saved.displayNameOverride, 'Jimmy Patel');
    expect(saved.phone, '+1 555 0100');
    expect(saved.company, 'Windowmaker');
    expect(saved.role, 'Estimator');
    expect(saved.effectiveName, 'Jimmy Patel'); // override wins over Google name
  });

  test('re-authenticating (without signing out) keeps edited fields', () async {
    await repo.signInWithGoogle();
    await repo.updateProfile(repo.current!.copyWith(
      displayNameOverride: 'Jimmy Patel',
      phone: '+1 555 0100',
    ));

    // Signing in again for the same account merges in the kept edits.
    final again = await repo.signInWithGoogle();
    expect(again.isOk, isTrue);
    expect(repo.current?.displayNameOverride, 'Jimmy Patel');
    expect(repo.current?.phone, '+1 555 0100');
  });

  test('signOut clears edited fields for the next sign-in', () async {
    await repo.signInWithGoogle();
    await repo.updateProfile(repo.current!.copyWith(displayNameOverride: 'Jimmy Patel'));

    await repo.signOut();
    expect(repo.current, isNull);

    // Fresh sign-in after sign-out starts from the Google identity only.
    await repo.signInWithGoogle();
    expect(repo.current?.displayNameOverride, isNull);
    expect(repo.current?.googleDisplayName, 'Demo User');
  });

  test('signOut clears the stored account and emits null', () async {
    await repo.signInWithGoogle();
    expect(repo.current, isNotNull);

    final emissions = <AuthUser?>[];
    final sub = repo.watch().listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 20)); // let watch subscribe

    await repo.signOut();

    expect(repo.current, isNull);
    expect(box.get(AppConstants.userKey), isNull);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.last, isNull);
    await sub.cancel();
  });
}
