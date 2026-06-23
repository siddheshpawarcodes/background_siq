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

  group('tolerant matching (real-world filenames)', () {
    test('matches space-separated language words', () async {
      await touch('Agnimantha/Agnimantha eng.m4a');
      await touch('Agnimantha/Agnimantha hindi.m4a');
      await touch('Agnimantha/Agnimantha san.m4a');

      expect(await scan('eng'), ['Agnimantha eng.m4a']);
      expect(await scan('hindi'), ['Agnimantha hindi.m4a']);
      expect(await scan('san'), ['Agnimantha san.m4a']);
    });

    test('a separator on the typed suffix is ignored (_eng == eng == " eng")',
        () async {
      await touch('a/Apamrga eng.m4a');
      expect(await scan('_eng'), ['Apamrga eng.m4a']);
      expect(await scan(' eng'), ['Apamrga eng.m4a']);
      expect(await scan('-eng'), ['Apamrga eng.m4a']);
    });

    test('matching is case-insensitive on both name and suffix', () async {
      await touch('a/Bala ENG.m4a');
      expect(await scan('eng'), ['Bala ENG.m4a']);
      expect(await scan('ENG'), ['Bala ENG.m4a']);
    });

    test('hyphen and underscore separators in the name are equivalent',
        () async {
      await touch('a/Bilva-eng.m4a');
      await touch('b/Bilva_eng.m4a');
      expect(await scan('eng'), ['Bilva-eng.m4a', 'Bilva_eng.m4a']);
    });

    test('still rejects a longer word sharing the token (whole-word only)',
        () async {
      await touch('a/Amalki english.m4a');
      await touch('a/Amalki eng.m4a');
      expect(await scan('eng'), ['Amalki eng.m4a']);
    });

    test('a misspelt language token does not match (must be renamed)',
        () async {
      await touch('a/Dhatakai engi.m4a'); // typo: "engi"
      await touch('a/Ashwagandha hindj.m4a'); // typo: "hindj"
      expect(await scanMany(['eng', 'hindi', 'san']), isEmpty);
    });
  });

  group('scanDetailed() diagnostics', () {
    test('reports unreadable when the root does not exist', () async {
      final r = await scanner.scanDetailed(
          rootFolder: p.join(root.path, 'nope'), suffixes: ['eng']);
      expect(r.rootReadable, isFalse);
      expect(r.matchedPaths, isEmpty);
      expect(r.audioFilesFound, 0);
    });

    test('separates "audio present but unmatched" from "no audio"', () async {
      await touch('Agnimantha/Agnimantha eng.m4a');
      await touch('Agnimantha/Agnimantha hindi.m4a');
      await touch('Notes/readme.txt');

      // Suffix that matches nothing, though audio files exist.
      final r = await scanner.scanDetailed(rootFolder: root.path, suffixes: ['_xx']);
      expect(r.rootReadable, isTrue);
      expect(r.matchedPaths, isEmpty);
      expect(r.audioFilesFound, 2);
      expect(r.sampleAudioNames, isNotEmpty);
    });

    test('returns matched paths alongside the audio count', () async {
      await touch('A/A eng.m4a');
      await touch('A/A hindi.m4a');

      final r = await scanner.scanDetailed(rootFolder: root.path, suffixes: ['eng']);
      expect(r.rootReadable, isTrue);
      expect(r.audioFilesFound, 2);
      expect(r.matchedPaths.map(p.basename), ['A eng.m4a']);
    });
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

  group('matchedSuffix()', () {
    test('returns the matched suffix', () {
      expect(
          DatasetFileScanner.matchedSuffix(
              '/x/Amalki_eng.m4a', ['_eng', '_hin'], {'m4a'}),
          '_eng');
    });

    test('returns null when nothing matches', () {
      expect(
          DatasetFileScanner.matchedSuffix(
              '/x/Amalki_other.m4a', ['_eng', '_hin'], {'m4a'}),
          isNull);
    });

    test('returns null for an unsupported extension', () {
      expect(
          DatasetFileScanner.matchedSuffix('/x/Amalki_eng.mp3', ['_eng'],
              {'m4a'}),
          isNull);
    });

    test('longest suffix wins when more than one matches', () {
      // Both `_en` and `_gen` end this name; the longer suffix is chosen so
      // routing to a profile is deterministic.
      expect(
          DatasetFileScanner.matchedSuffix(
              '/x/clip_gen.m4a', ['_en', '_gen'], {'m4a'}),
          '_gen');
      // Order-independent: same result regardless of how suffixes are listed.
      expect(
          DatasetFileScanner.matchedSuffix(
              '/x/clip_gen.m4a', ['_gen', '_en'], {'m4a'}),
          '_gen');
    });
  });
}
