import 'package:hive_ce/hive.dart';

part 'history_model.g.dart';

/// Hive persistence DTO for a processing-history entry (SRS §8.2).
@HiveType(typeId: 2)
class HistoryModel extends HiveObject {
  HistoryModel({
    required this.id,
    required this.sourcePath,
    required this.outputPath,
    required this.date,
    required this.profileName,
    required this.processingMillis,
    required this.status,
  });

  @HiveField(0)
  String id;
  @HiveField(1)
  String sourcePath;
  @HiveField(2)
  String outputPath;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  String profileName;
  @HiveField(5)
  int processingMillis;
  @HiveField(6)
  int status; // JobStatus.index
}
