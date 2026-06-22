import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'background_profile.freezed.dart';
part 'background_profile.g.dart';

/// A reusable, calibratable audio-processing profile (SRS §7.1; Calibration
/// design §3). Pure domain entity. JSON (`toJson`/`fromJson`) backs profile
/// export/import; enums serialize as readable strings.
@freezed
abstract class BackgroundProfile with _$BackgroundProfile {
  const factory BackgroundProfile({
    required String id,
    required String name,
    String? description, // optional, shown in wizard
    String? musicFilePath,
    String? coverImagePath, // optional cover art embedded in every export
    String? calibrationVoiceSamplePath, // calibration/preview only (design §9 E6)
    @Default(100) int voiceVolume, // 0..100 — level of the spoken/audio track
    @Default(20) int musicVolume, // 0..100 — level of the background music
    @Default(NoiseLevel.medium) NoiseLevel noiseReduction,
    @Default(true) bool voiceEnhancementEnabled,
    @Default(DuckingStrength.medium) DuckingStrength ducking,
    @Default(0.0) double fadeInSeconds, // 0..10
    @Default(0.0) double fadeOutSeconds, // 0..10
    @Default(true) bool normalizationEnabled,
    @Default(ExportFormat.mp3) ExportFormat exportFormat,
    required DateTime createdDate,
    required DateTime modifiedDate,
  }) = _BackgroundProfile;

  factory BackgroundProfile.fromJson(Map<String, dynamic> json) =>
      _$BackgroundProfileFromJson(json);
}
