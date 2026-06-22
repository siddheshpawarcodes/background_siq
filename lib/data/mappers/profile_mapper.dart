import '../../domain/entities/background_profile.dart';
import '../../domain/entities/enums.dart';
import '../models/profile_model.dart';
import 'enum_mapper.dart';

/// Maps [ProfileModel] (Hive) ⇄ [BackgroundProfile] (domain).
extension ProfileModelMapper on ProfileModel {
  BackgroundProfile toEntity() => BackgroundProfile(
        id: id,
        name: name,
        description: description,
        calibrationVoiceSamplePath: calibrationVoiceSamplePath,
        musicFilePath: musicFilePath,
        coverImagePath: coverImagePath,
        musicVolume: musicVolume,
        noiseReduction: NoiseLevel.values.fromIndex(noiseReductionLevel),
        voiceEnhancementEnabled: voiceEnhancementEnabled,
        ducking: DuckingStrength.values.fromIndex(duckingStrength),
        fadeInSeconds: fadeInSeconds,
        fadeOutSeconds: fadeOutSeconds,
        normalizationEnabled: normalizationEnabled,
        exportFormat: ExportFormat.values.fromIndex(exportFormat),
        createdDate: createdDate,
        modifiedDate: modifiedDate,
      );
}

extension BackgroundProfileMapper on BackgroundProfile {
  ProfileModel toModel() => ProfileModel(
        id: id,
        name: name,
        description: description,
        calibrationVoiceSamplePath: calibrationVoiceSamplePath,
        musicFilePath: musicFilePath,
        coverImagePath: coverImagePath,
        musicVolume: musicVolume,
        noiseReductionLevel: noiseReduction.index,
        voiceEnhancementEnabled: voiceEnhancementEnabled,
        duckingStrength: ducking.index,
        fadeInSeconds: fadeInSeconds,
        fadeOutSeconds: fadeOutSeconds,
        normalizationEnabled: normalizationEnabled,
        exportFormat: exportFormat.index,
        createdDate: createdDate,
        modifiedDate: modifiedDate,
      );
}
