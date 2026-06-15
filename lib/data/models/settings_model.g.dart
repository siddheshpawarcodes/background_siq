// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      defaultExportFolder: fields[0] as String?,
      defaultExportFormat: (fields[1] as num).toInt(),
      themeMode: (fields[2] as num).toInt(),
      autoOpenOutputFolder: fields[3] as bool,
      loggingEnabled: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.defaultExportFolder)
      ..writeByte(1)
      ..write(obj.defaultExportFormat)
      ..writeByte(2)
      ..write(obj.themeMode)
      ..writeByte(3)
      ..write(obj.autoOpenOutputFolder)
      ..writeByte(4)
      ..write(obj.loggingEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
