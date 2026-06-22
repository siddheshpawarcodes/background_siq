import 'dart:io';

import 'package:echobug/core/result/result.dart';
import 'package:echobug/domain/entities/audio_file_ref.dart';
import 'package:echobug/domain/ports/file_system_port.dart';
import 'package:echobug/services/dataset/mirrored_output_file_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Records the preferredDir it was asked to resolve into.
class _RecordingFs implements FileSystemPort {
  String? lastPreferredDir;

  @override
  Future<Result<String>> resolveOutputPath(
      {required AudioFileRef source, String? preferredDir}) async {
    lastPreferredDir = preferredDir;
    return Result.ok('$preferredDir/${source.name}');
  }

  @override
  Future<String> previewPath(String extension) async => '/tmp/p.$extension';

  @override
  Future<bool> exists(String path) async => true;
}

void main() {
  late Directory outputRoot;

  setUp(() async {
    outputRoot = await Directory.systemTemp.createTemp('mirror_out_');
  });
  tearDown(() async {
    if (await outputRoot.exists()) await outputRoot.delete(recursive: true);
  });

  test('mirrors the source tree (incl. the selected folder name) under outputRoot',
      () async {
    final inner = _RecordingFs();
    final sourceRoot = p.join('/dataset', 'music data');
    final fs = MirroredOutputFileSystem(
      inner,
      sourceRoot: sourceRoot,
      outputRoot: outputRoot.path,
    );

    final source = AudioFileRef(
      path: p.join(sourceRoot, 'Amalki', 'Amalki_eng.m4a'),
      name: 'Amalki_eng.m4a',
      ext: 'm4a',
    );

    await fs.resolveOutputPath(
      source: source,
      preferredDir: '/some/ignored/export/folder',
    );

    // Music/EchoBug already encoded in outputRoot; here we assert the relative
    // mirror: <outputRoot>/music data/Amalki — the selected root's own name is
    // reproduced, then the subfolder.
    expect(inner.lastPreferredDir,
        p.join(outputRoot.path, 'music data', 'Amalki'));
    // The directory was actually created on disk.
    expect(await Directory(inner.lastPreferredDir!).exists(), isTrue);
  });

  test('a file directly in the root mirrors to just the root folder name',
      () async {
    final inner = _RecordingFs();
    final sourceRoot = p.join('/dataset', 'music data');
    final fs = MirroredOutputFileSystem(
      inner,
      sourceRoot: sourceRoot,
      outputRoot: outputRoot.path,
    );

    final source = AudioFileRef(
      path: p.join(sourceRoot, 'loose_eng.m4a'),
      name: 'loose_eng.m4a',
      ext: 'm4a',
    );

    await fs.resolveOutputPath(source: source);

    expect(inner.lastPreferredDir, p.join(outputRoot.path, 'music data'));
  });

  test('delegates exists and previewPath to the inner port', () async {
    final fs = MirroredOutputFileSystem(
      _RecordingFs(),
      sourceRoot: '/dataset',
      outputRoot: outputRoot.path,
    );
    expect(await fs.exists('/anything'), isTrue);
    expect(await fs.previewPath('m4a'), '/tmp/p.m4a');
  });
}
