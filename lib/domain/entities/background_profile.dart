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
    String? coverImagePath, // optional cover-art image embedded in output (thumbnail)
    String? calibrationVoiceSamplePath, // calibration/preview only (design §9 E6)
    @Default(100) int voiceVolume, // 0..100 — level of the spoken/audio track
    @Default(20) int musicVolume, // 0..100 — level of the background music
    @Default(NoiseLevel.medium) NoiseLevel noiseReduction,
    @Default(true) bool voiceEnhancementEnabled,
    @Default(DuckingStrength.medium) DuckingStrength ducking,
    @Default(0.0) double fadeInSeconds, // 0..10
    @Default(0.0) double fadeOutSeconds, // 0..10
    // Tone EQ applied to the voice/audio track. Each band is gain in dB
    // (-12..12); 0 is a no-op, so the default profile adds no EQ filter.
    @Default(0.0) double eqBassDb,
    @Default(0.0) double eqMidDb,
    @Default(0.0) double eqTrebleDb,
    @Default(true) bool normalizationEnabled,
    @Default(ExportFormat.mp3) ExportFormat exportFormat,
    // Encoder bitrate (kbps) for lossy output containers (mp3/aac/ogg). Null
    // keeps the per-codec default (mp3 320, aac 256, ogg q6); lossless
    // containers (wav/flac) ignore it.
    int? audioBitrateKbps,
    required DateTime createdDate,
    required DateTime modifiedDate,
  }) = _BackgroundProfile;

  factory BackgroundProfile.fromJson(Map<String, dynamic> json) =>
      _$BackgroundProfileFromJson(json);
}
