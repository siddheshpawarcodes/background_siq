import 'package:path/path.dart' as p;

import '../../../domain/entities/history_entry.dart';

/// A single playable item in the music-player queue, derived from a completed
/// [HistoryEntry]. Decoupled from the persistence model so the player UI reads
/// only what it needs (file path + display labels).
class PlayerTrack {
  const PlayerTrack({
    required this.id,
    required this.path,
    required this.title,
    required this.profileName,
    required this.date,
  });

  /// History entry id — stable identity used to resolve the start track.
  final String id;

  /// Absolute path to the finished output file on disk.
  final String path;

  /// Display title — the output file name without its extension.
  final String title;

  /// Background-music profile applied during processing.
  final String profileName;

  /// When the file was produced.
  final DateTime date;

  factory PlayerTrack.fromHistory(HistoryEntry entry) => PlayerTrack(
        id: entry.id,
        path: entry.outputPath,
        title: p.basenameWithoutExtension(entry.outputPath),
        profileName: entry.profileName,
        date: entry.date,
      );

  /// `Profile · YYYY-MM-DD` — the now-playing / list subtitle.
  String get subtitle {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$profileName · ${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
