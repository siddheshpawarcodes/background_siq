import '../../domain/entities/enums.dart';
import '../../domain/entities/history_entry.dart';
import '../models/history_model.dart';
import 'enum_mapper.dart';

/// Maps [HistoryModel] (Hive) ⇄ [HistoryEntry] (domain).
extension HistoryModelMapper on HistoryModel {
  HistoryEntry toEntity() => HistoryEntry(
        id: id,
        sourcePath: sourcePath,
        outputPath: outputPath,
        date: date,
        profileName: profileName,
        processingTime: Duration(milliseconds: processingMillis),
        status: JobStatus.values.fromIndex(status),
      );
}

extension HistoryEntryMapper on HistoryEntry {
  HistoryModel toModel() => HistoryModel(
        id: id,
        sourcePath: sourcePath,
        outputPath: outputPath,
        date: date,
        profileName: profileName,
        processingMillis: processingTime.inMilliseconds,
        status: status.index,
      );
}
