import 'dart:io';

import 'package:echobug/services/dataset/dataset_file_scanner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  Future<void> touch(String relative) async {
    final file = File(p.join(root.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString('x');
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dataset_scan_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  const scanner = DatasetFileScanner();

  Future<List<String>> scanMany(List<String> suffixes,
          {Set<String> exts = DatasetFileScanner.defaultExtensions}) async =>
      (await scanner
              .scan(rootFolder: root.path, suffixes: suffixes, extensions: exts)
              .toList())
          .map((path) => p.basename(path))
          .toList()
        ..sort();

  Future<List<String>> scan(String suffix,
          {Set<String> exts = DatasetFileScanner.defaultExtensions}) =>
      scanMany([suffix], exts: exts);

  test('finds matching files across nested subfolders', () async {
    await touch('Amalki/Amalki_eng.m4a');
    await touch('Brahmi/Brahmi_eng.m4a');
    await touch('Herbs/Deep/Nested/Deep_eng.m4a');

    expect(await scan('_eng'),
        ['Amalki_eng.m4a', 'Brahmi_eng.m4a', 'Deep_eng.m4a']);
  });

  test('filters by exact suffix and ignores near-misses', () async {
    await touch('Amalki/Amalki_eng.m4a');
    await touch('Amalki/Amalki_hindi.m4a');
    await touch('Amalki/Amalki_san.m4a');
    await touch('Amalki/Amalki_english.m4a'); // longer word, must be ignored

    expect(await scan('_eng'), ['Amalki_eng.m4a']);
    expect(await scan('_hindi'), ['Amalki_hindi.m4a']);
    expect(await scan('_san'), ['Amalki_san.m4a']);
  });

  test('matches files ending with any of multiple suffixes', () async {
    await touch('Amalki/Amalki_eng.m4a');
    await touch('Amalki/Amalki_hin.m4a');
    await touch('Amalki/Amalki_san.m4a');
    await touch('Brahmi/Brahmi_eng.m4a');
    await touch('Brahmi/Brahmi_other.m4a'); // not requested

    expect(await scanMany(['_eng', '_hin', '_san']), [
      'Amalki_eng.m4a',
      'Amalki_hin.m4a',
      'Amalki_san.m4a',
      'Brahmi_eng.m4a',
    ]);
  });

  test('matches m4a only in phase 1, ignoring other extensions', () async {
    await touch('a/song_eng.m4a');
    await touch('a/song_eng.mp3');
    await touch('a/song_eng.wav');
    await touch('a/notes.txt');

    expect(await scan('_eng'), ['song_eng.m4a']);
  });

  test('extension matching is case-insensitive', () async {
    await touch('a/Case_eng.M4A');
    expect(await scan('_eng'), ['Case_eng.M4A']);
  });

  test('extension set is configurable for future formats', () async {
    await touch('a/song_eng.m4a');
    await touch('a/song_eng.mp3');

    final result = await scan('_eng', exts: {'m4a', 'mp3'});
    expect(result, ['song_eng.m4a', 'song_eng.mp3']);
  });

  test('returns empty for a non-existent root', () async {
    final result = await scanner
        .scan(rootFolder: p.join(root.path, 'nope'), suffixes: ['_eng'])
        .toList();
    expect(result, isEmpty);
  });

  test('handles a large dataset', () async {
    for (var folder = 0; folder < 50; folder++) {
      await touch('folder$folder/item${folder}_eng.m4a');
      await touch('folder$folder/item${folder}_hindi.m4a');
    }
    final result = await scan('_eng');
    expect(result, hasLength(50));
  });

  group('matchesAny() predicate', () {
    test('accepts exact suffix + extension', () {
      expect(
          DatasetFileScanner.matchesAny('/x/Amalki_eng.m4a', ['_eng'], {'m4a'}),
          isTrue);
    });

    test('accepts when any one of several suffixes matches', () {
      expect(
          DatasetFileScanner.matchesAny(
              '/x/Amalki_san.m4a', ['_eng', '_hin', '_san'], {'m4a'}),
          isTrue);
    });

    test('rejects a longer word with the same prefix', () {
      expect(
          DatasetFileScanner.matchesAny(
              '/x/Amalki_english.m4a', ['_eng'], {'m4a'}),
          isFalse);
    });

    test('rejects when none of the suffixes match', () {
      expect(
          DatasetFileScanner.matchesAny(
              '/x/Amalki_hindi.m4a', ['_eng', '_san'], {'m4a'}),
          isFalse);
    });

    test('rejects unsupported extension', () {
      expect(
          DatasetFileScanner.matchesAny('/x/Amalki_eng.mp3', ['_eng'], {'m4a'}),
          isFalse);
    });
  });
}
