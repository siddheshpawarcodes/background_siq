import 'package:hive_ce/hive.dart';

part 'recent_file_model.g.dart';

/// Hive persistence DTO for a recently-picked source file (SRS §8.2).
@HiveType(typeId: 3)
class RecentFileModel extends HiveObject {
  RecentFileModel({
    required this.path,
    required this.name,
    required this.ext,
    this.sizeBytes,
    this.durationMillis,
    required this.lastUsed,
  });

  @HiveField(0)
  String path;
  @HiveField(1)
  String name;
  @HiveField(2)
  String ext;
  @HiveField(3)
  int? sizeBytes;
  @HiveField(4)
  int? durationMillis;
  @HiveField(5)
  DateTime lastUsed;
}
