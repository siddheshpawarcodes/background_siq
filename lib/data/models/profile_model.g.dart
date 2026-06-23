// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileModelAdapter extends TypeAdapter<ProfileModel> {
  @override
  final typeId = 0;

  @override
  ProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileModel(
      id: fields[0] as String,
      name: fields[1] as String,
      musicFilePath: fields[2] as String?,
      voiceVolume: (fields[17] as num?)?.toInt(),
      musicVolume: (fields[3] as num).toInt(),
      noiseReductionLevel: (fields[4] as num).toInt(),
      voiceEnhancementEnabled: fields[5] as bool,
      duckingStrength: (fields[6] as num).toInt(),
      fadeInSeconds: (fields[7] as num).toDouble(),
      fadeOutSeconds: (fields[8] as num).toDouble(),
      normalizationEnabled: fields[9] as bool,
      exportFormat: (fields[10] as num).toInt(),
      createdDate: fields[11] as DateTime,
      modifiedDate: fields[12] as DateTime,
      description: fields[13] as String?,
      calibrationVoiceSamplePath: fields[14] as String?,
      coverImagePath: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.musicFilePath)
      ..writeByte(3)
      ..write(obj.musicVolume)
      ..writeByte(4)
      ..write(obj.noiseReductionLevel)
      ..writeByte(5)
      ..write(obj.voiceEnhancementEnabled)
      ..writeByte(6)
      ..write(obj.duckingStrength)
      ..writeByte(7)
      ..write(obj.fadeInSeconds)
      ..writeByte(8)
      ..write(obj.fadeOutSeconds)
      ..writeByte(9)
      ..write(obj.normalizationEnabled)
      ..writeByte(10)
      ..write(obj.exportFormat)
      ..writeByte(11)
      ..write(obj.createdDate)
      ..writeByte(12)
      ..write(obj.modifiedDate)
      ..writeByte(13)
      ..write(obj.description)
      ..writeByte(14)
      ..write(obj.calibrationVoiceSamplePath)
      ..writeByte(16)
      ..write(obj.coverImagePath)
      ..writeByte(17)
      ..write(obj.voiceVolume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
