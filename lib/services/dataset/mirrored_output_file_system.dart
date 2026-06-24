import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/audio_file_ref.dart';
import '../../domain/ports/file_system_port.dart';
import '../../core/result/result.dart';

/// [FileSystemPort] decorator that writes each processed file into a *mirror of
/// the source tree*, rooted at a separate [outputRoot].
///
/// For Dataset Batch the engine (FFmpeg) writes to an app-private *staging*
/// root; the finished file is then published into the public `Music/EchoBug/`
/// folder via MediaStore (`MediaStorePort`). Staging mirrors the source layout —
/// including the selected root folder's own name — so the public relative path
/// can be reconstructed and same-named files in different folders never clash:
///
/// ```
/// sourceRoot = .../Download/music data
/// source     = .../Download/music data/Amalki/Amalki_eng.m4a
/// outputRoot = <app staging>/dataset
/// staged dir = <app staging>/dataset/music data/Amalki/
/// public     = Music/EchoBug/music data/Amalki/   (resolved by the publisher)
/// ```
///
/// It delegates to the real [FileSystemPort] (passing the mirrored directory as
/// `preferredDir`) so the `_echobug` suffix and `_1`/`_2` collision-avoidance
/// logic are reused unchanged.
class MirroredOutputFileSystem implements FileSystemPort {
  const MirroredOutputFileSystem(
    this._inner, {
    required this.sourceRoot,
    required this.outputRoot,
  });

  final FileSystemPort _inner;

  /// Absolute path of the dataset root the user selected.
  final String sourceRoot;

  /// Absolute path of the base folder to mirror the tree into.
  final String outputRoot;

  @override
  Future<Result<String>> resolveOutputPath({
    required AudioFileRef source,
    String? preferredDir,
  }) async {
    final targetDir = p.join(outputRoot, mirrorRelativeDir(sourceRoot, source.path));
    // Best-effort create so the inner service's writability probe passes. A
    // failure here is non-fatal: the inner service then falls back to its
    // default export folder rather than aborting the file.
    try {
      await Directory(targetDir).create(recursive: true);
    } catch (_) {
      // Ignored — handled by the inner fallback.
    }
    return _inner.resolveOutputPath(source: source, preferredDir: targetDir);
  }

  @override
  Future<String> previewPath(String extension, {String? token}) =>
      _inner.previewPath(extension, token: token);

  @override
  Future<void> clearPreviews() => _inner.clearPreviews();

  @override
  Future<bool> exists(String path) => _inner.exists(path);

  /// The source file's directory relative to [sourceRoot], *including the
  /// basename of [sourceRoot] itself*, with forward-slash joins.
  ///
  /// e.g. sourceRoot `…/music data`, source `…/music data/Amalki/x.m4a`
  /// → `music data/Amalki`. A file directly in the root → `music data`.
  static String mirrorRelativeDir(String sourceRoot, String sourcePath) {
    final root = p.normalize(sourceRoot);
    final rootName = p.basename(root);
    final relDir = p.relative(p.dirname(sourcePath), from: root);
    final segments = <String>[
      if (rootName.isNotEmpty && rootName != '.') rootName,
      if (relDir.isNotEmpty && relDir != '.') relDir,
    ];
    return p.joinAll(segments);
  }

  /// Resolves the app-private base directory FFmpeg stages dataset output into
  /// before it is published to the public Music folder. App-private storage is
  /// always writable and needs no permission.
  static Future<String> resolveStagingRoot() async {
    final support = await getApplicationSupportDirectory();
    return p.join(support.path, 'dataset_staging');
  }
}
