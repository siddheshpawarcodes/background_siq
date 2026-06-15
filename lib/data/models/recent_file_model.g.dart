// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_file_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecentFileModelAdapter extends TypeAdapter<RecentFileModel> {
  @override
  final typeId = 3;

  @override
  RecentFileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecentFileModel(
      path: fields[0] as String,
      name: fields[1] as String,
      ext: fields[2] as String,
      sizeBytes: (fields[3] as num?)?.toInt(),
      durationMillis: (fields[4] as num?)?.toInt(),
      lastUsed: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecentFileModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ext)
      ..writeByte(3)
      ..write(obj.sizeBytes)
      ..writeByte(4)
      ..write(obj.durationMillis)
      ..writeByte(5)
      ..write(obj.lastUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentFileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
