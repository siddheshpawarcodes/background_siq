import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'history_entry.freezed.dart';

/// A record of one completed (or failed) processing run (SRS §7.1, §11.5).
@freezed
abstract class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String id,
    required String sourcePath,
    required String outputPath,
    required DateTime date,
    required String profileName,
    required Duration processingTime,
    required JobStatus status,
  }) = _HistoryEntry;
}
