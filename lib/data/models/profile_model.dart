import 'package:hive_ce/hive.dart';

part 'profile_model.g.dart';

/// Hive persistence DTO for a background-music profile (SRS §8.2).
///
/// Enums are stored as their `int` index for migration safety; the mapper
/// layer converts to/from domain enums.
@HiveType(typeId: 0)
class ProfileModel extends HiveObject {
  ProfileModel({
    required this.id,
    required this.name,
    this.musicFilePath,
    this.voiceVolume,
    required this.musicVolume,
    required this.noiseReductionLevel,
    required this.voiceEnhancementEnabled,
    required this.duckingStrength,
    required this.fadeInSeconds,
    required this.fadeOutSeconds,
    required this.normalizationEnabled,
    required this.exportFormat,
    required this.createdDate,
    required this.modifiedDate,
    this.description,
    this.calibrationVoiceSamplePath,
    this.coverImagePath,
  });

  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String? musicFilePath;
  @HiveField(3)
  int musicVolume;
  @HiveField(4)
  int noiseReductionLevel; // NoiseLevel.index
  @HiveField(5)
  bool voiceEnhancementEnabled;
  @HiveField(6)
  int duckingStrength; // DuckingStrength.index
  @HiveField(7)
  double fadeInSeconds;
  @HiveField(8)
  double fadeOutSeconds;
  @HiveField(9)
  bool normalizationEnabled;
  @HiveField(10)
  int exportFormat; // ExportFormat.index
  @HiveField(11)
  DateTime createdDate;
  @HiveField(12)
  DateTime modifiedDate;
  // Fields 13/14 appended for the Calibration feature. Backward-compatible:
  // older records read these as null.
  @HiveField(13)
  String? description;
  @HiveField(14)
  String? calibrationVoiceSamplePath;
  // Field 15 appended for the audio/voice volume control. Backward-compatible:
  // older records read this as null and fall back to the default in the mapper.
  @HiveField(15)
  int? voiceVolume; // 0..100
  // Field 16 appended for embedded cover art. Backward-compatible: older
  // records read this as null (no thumbnail).
  @HiveField(16)
  String? coverImagePath;
}
