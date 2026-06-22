import 'dart:io';

import 'package:path/path.dart' as p;

/// Recursively discovers audio files in a dataset folder that match one of a
/// set of filename suffixes.
///
/// Backed by [Directory.list] which walks the tree lazily and asynchronously,
/// so the main isolate stays responsive and the full file tree is never
/// materialised in memory — only matching paths are yielded.
///
/// Phase 1 matches `.m4a` only; [extensions] is configurable so `.mp3`, `.wav`,
/// `.aac` can be added later without changing the matching logic.
class DatasetFileScanner {
  const DatasetFileScanner();

  /// Default audio extensions matched (lower-case, no dot). Phase 1: m4a only.
  static const Set<String> defaultExtensions = {'m4a'};

  /// Yields absolute paths of files under [rootFolder] (recursively) whose name
  /// ends with `<suffix>.<ext>` for *any* suffix in [suffixes] and any ext in
  /// [extensions].
  ///
  /// Each suffix is matched case-sensitively (it is exactly what the user
  /// typed, e.g. `_eng`), while the extension is matched case-insensitively
  /// (`.m4a` / `.M4A`). This rejects near-misses like `Amalki_english.m4a` when
  /// the suffix is `_eng`, per the matching rules.
  ///
  /// Unreadable subdirectories are skipped rather than aborting the whole scan.
  Stream<String> scan({
    required String rootFolder,
    required Iterable<String> suffixes,
    Set<String> extensions = defaultExtensions,
  }) async* {
    final root = Directory(rootFolder);
    if (!await root.exists()) return;

    final suffixList = suffixes.where((s) => s.isNotEmpty).toList();
    if (suffixList.isEmpty) return;
    final exts = extensions.map((e) => e.toLowerCase()).toSet();

    await for (final entity
        in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (_matches(entity.path, suffixList, exts)) {
        yield entity.path;
      }
    }
  }

  /// Pure matching predicate, exposed for unit testing. True when [path] ends
  /// with any suffix in [suffixes] followed by any extension in [extensions].
  static bool matchesAny(
    String path,
    Iterable<String> suffixes,
    Set<String> extensions,
  ) =>
      _matches(
        path,
        suffixes.where((s) => s.isNotEmpty).toList(),
        extensions.map((e) => e.toLowerCase()).toSet(),
      );

  static bool _matches(
    String path,
    List<String> suffixes,
    Set<String> lowerExts,
  ) {
    final name = p.basename(path);
    final lowerName = name.toLowerCase();
    for (final ext in lowerExts) {
      final tail = '.$ext';
      if (!lowerName.endsWith(tail)) continue;
      final nameWithoutExt = name.substring(0, name.length - tail.length);
      for (final suffix in suffixes) {
        if (nameWithoutExt.endsWith(suffix)) return true;
      }
    }
    return false;
  }
}
