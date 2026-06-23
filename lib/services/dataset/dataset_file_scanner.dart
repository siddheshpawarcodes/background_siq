import 'dart:io';

import 'package:path/path.dart' as p;

/// Outcome of a diagnostic scan ([DatasetFileScanner.scanDetailed]): the matched
/// paths plus enough context to explain a zero-match result to the user.
class DatasetScanResult {
  const DatasetScanResult({
    required this.rootReadable,
    required this.matchedPaths,
    required this.audioFilesFound,
    required this.sampleAudioNames,
  });

  /// False when the root folder doesn't exist or couldn't be listed (e.g. a
  /// permission problem on Android). When false, the other fields are empty.
  final bool rootReadable;

  /// Absolute paths of files matching one of the configured suffixes.
  final List<String> matchedPaths;

  /// Count of audio files (matching the extensions, regardless of suffix) seen
  /// under the root — lets the caller tell "no audio at all" apart from "audio
  /// present, but no suffix matched".
  final int audioFilesFound;

  /// A handful of example audio file names found (regardless of suffix), so the
  /// UI can show the user why their suffixes didn't match.
  final List<String> sampleAudioNames;
}

/// Recursively discovers audio files in a dataset folder that match one of a
/// set of filename suffixes.
///
/// Backed by [Directory.list] which walks the tree lazily and asynchronously,
/// so the main isolate stays responsive and the full file tree is never
/// materialised in memory — only matching paths are yielded.
///
/// Phase 1 matches `.m4a` only; [extensions] is configurable so `.mp3`, `.wav`,
/// `.aac` can be added later without changing the matching logic.
///
/// ## Suffix matching
/// A suffix matches when it is the **last whole word** of the filename (before
/// the extension). Matching is *tolerant* of how real-world datasets are named:
/// spaces, underscores and hyphens are all treated as the same word separator,
/// and case is ignored. So a suffix typed as `_eng`, ` eng` or `ENG` all match
/// `Agnimantha eng.m4a`, `Amalki-Eng.m4a` and `clip_eng.m4a` alike. It is still
/// a *whole-word* match, so `eng` does **not** match `Amalki_english.m4a`.
class DatasetFileScanner {
  const DatasetFileScanner();

  /// Default audio extensions matched (lower-case, no dot). Phase 1: m4a only.
  static const Set<String> defaultExtensions = {'m4a'};

  /// Runs of separator characters (space, underscore, hyphen) are collapsed to
  /// a single space during normalisation, so they all compare equal.
  static final RegExp _separators = RegExp(r'[\s_\-]+');

  /// Yields absolute paths of files under [rootFolder] (recursively) whose name
  /// matches any suffix in [suffixes] (see class docs for the matching rules)
  /// and any ext in [extensions].
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

  /// Like [scan] but returns a single [DatasetScanResult] with diagnostics:
  /// whether the root was readable, the matched paths, how many audio files
  /// exist regardless of suffix, and a few example names. Used to explain a
  /// zero-match run instead of failing silently.
  Future<DatasetScanResult> scanDetailed({
    required String rootFolder,
    required Iterable<String> suffixes,
    Set<String> extensions = defaultExtensions,
    int sampleLimit = 5,
  }) async {
    final root = Directory(rootFolder);
    if (!await root.exists()) return _unreadable;

    final suffixList = suffixes.where((s) => s.isNotEmpty).toList();
    final exts = extensions.map((e) => e.toLowerCase()).toSet();

    final matched = <String>[];
    final samples = <String>[];
    var audioCount = 0;

    try {
      await for (final entity
          in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!_hasAudioExtension(name, exts)) continue;
        audioCount++;
        if (samples.length < sampleLimit) samples.add(name);
        if (suffixList.isNotEmpty && _matches(entity.path, suffixList, exts)) {
          matched.add(entity.path);
        }
      }
    } on FileSystemException {
      // The tree couldn't be fully read (e.g. permission). If we got nothing at
      // all, report the root as unreadable so the user gets the permission hint
      // rather than a misleading "no files found" message.
      if (audioCount == 0 && matched.isEmpty) return _unreadable;
    }

    return DatasetScanResult(
      rootReadable: true,
      matchedPaths: matched,
      audioFilesFound: audioCount,
      sampleAudioNames: samples,
    );
  }

  static const DatasetScanResult _unreadable = DatasetScanResult(
    rootReadable: false,
    matchedPaths: [],
    audioFilesFound: 0,
    sampleAudioNames: [],
  );

  /// Pure matching predicate, exposed for unit testing. True when [path]'s name
  /// (before the extension) ends with any suffix in [suffixes] as a whole word,
  /// per the class's tolerant matching rules.
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

  /// Returns the suffix from [suffixes] that [path] matches, or null if none.
  ///
  /// When a name matches more than one configured suffix, the suffix with the
  /// **longest** normalised token wins, so routing each file to a suffix's
  /// profile is deterministic. Matching follows the same tolerant rules as
  /// [scan].
  static String? matchedSuffix(
    String path,
    Iterable<String> suffixes,
    Set<String> extensions,
  ) {
    final lowerExts = extensions.map((e) => e.toLowerCase()).toSet();
    final normName = _normalizedStem(path, lowerExts);
    if (normName == null) return null;
    String? best;
    var bestLen = -1;
    for (final suffix in suffixes) {
      final token = _normalize(suffix);
      if (_tokenEndsName(normName, token) && token.length > bestLen) {
        best = suffix;
        bestLen = token.length;
      }
    }
    return best;
  }

  static bool _matches(
    String path,
    List<String> suffixes,
    Set<String> lowerExts,
  ) {
    final normName = _normalizedStem(path, lowerExts);
    if (normName == null) return false;
    for (final suffix in suffixes) {
      if (_tokenEndsName(normName, _normalize(suffix))) return true;
    }
    return false;
  }

  /// Returns the normalised filename stem (name minus a matching extension), or
  /// null when [path]'s extension isn't in [lowerExts].
  static String? _normalizedStem(String path, Set<String> lowerExts) {
    final name = p.basename(path);
    final lowerName = name.toLowerCase();
    for (final ext in lowerExts) {
      final tail = '.$ext';
      if (lowerName.endsWith(tail)) {
        return _normalize(name.substring(0, name.length - tail.length));
      }
    }
    return null;
  }

  static bool _hasAudioExtension(String name, Set<String> lowerExts) {
    final lower = name.toLowerCase();
    for (final ext in lowerExts) {
      if (lower.endsWith('.$ext')) return true;
    }
    return false;
  }

  /// Lower-cases [s] and collapses any run of separators (space/underscore/
  /// hyphen) to a single space, trimming the ends, so `_eng`, ` eng` and `-ENG`
  /// all normalise to `eng`.
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(_separators, ' ').trim();

  /// True when [normToken] is the last whole word of [normName] (both already
  /// normalised). Whole-word so `eng` matches `amalki eng` but not
  /// `amalki english`.
  static bool _tokenEndsName(String normName, String normToken) {
    if (normToken.isEmpty) return false;
    return normName == normToken || normName.endsWith(' $normToken');
  }
}
