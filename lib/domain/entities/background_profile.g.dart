// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackgroundProfile _$BackgroundProfileFromJson(Map<String, dynamic> json) =>
    _BackgroundProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      musicFilePath: json['musicFilePath'] as String?,
      calibrationVoiceSamplePath: json['calibrationVoiceSamplePath'] as String?,
      musicVolume: (json['musicVolume'] as num?)?.toInt() ?? 20,
      noiseReduction:
          $enumDecodeNullable(_$NoiseLevelEnumMap, json['noiseReduction']) ??
          NoiseLevel.medium,
      voiceEnhancementEnabled: json['voiceEnhancementEnabled'] as bool? ?? true,
      ducking:
          $enumDecodeNullable(_$DuckingStrengthEnumMap, json['ducking']) ??
          DuckingStrength.medium,
      fadeInSeconds: (json['fadeInSeconds'] as num?)?.toDouble() ?? 0.0,
      fadeOutSeconds: (json['fadeOutSeconds'] as num?)?.toDouble() ?? 0.0,
      normalizationEnabled: json['normalizationEnabled'] as bool? ?? true,
      exportFormat:
          $enumDecodeNullable(_$ExportFormatEnumMap, json['exportFormat']) ??
          ExportFormat.mp3,
      createdDate: DateTime.parse(json['createdDate'] as String),
      modifiedDate: DateTime.parse(json['modifiedDate'] as String),
    );

Map<String, dynamic> _$BackgroundProfileToJson(_BackgroundProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'musicFilePath': instance.musicFilePath,
      'calibrationVoiceSamplePath': instance.calibrationVoiceSamplePath,
      'musicVolume': instance.musicVolume,
      'noiseReduction': _$NoiseLevelEnumMap[instance.noiseReduction]!,
      'voiceEnhancementEnabled': instance.voiceEnhancementEnabled,
      'ducking': _$DuckingStrengthEnumMap[instance.ducking]!,
      'fadeInSeconds': instance.fadeInSeconds,
      'fadeOutSeconds': instance.fadeOutSeconds,
      'normalizationEnabled': instance.normalizationEnabled,
      'exportFormat': _$ExportFormatEnumMap[instance.exportFormat]!,
      'createdDate': instance.createdDate.toIso8601String(),
      'modifiedDate': instance.modifiedDate.toIso8601String(),
    };

const _$NoiseLevelEnumMap = {
  NoiseLevel.off: 'off',
  NoiseLevel.mild: 'mild',
  NoiseLevel.medium: 'medium',
  NoiseLevel.aggressive: 'aggressive',
};

const _$DuckingStrengthEnumMap = {
  DuckingStrength.off: 'off',
  DuckingStrength.light: 'light',
  DuckingStrength.medium: 'medium',
  DuckingStrength.strong: 'strong',
};

const _$ExportFormatEnumMap = {
  ExportFormat.mp3: 'mp3',
  ExportFormat.aac: 'aac',
  ExportFormat.wav: 'wav',
};
