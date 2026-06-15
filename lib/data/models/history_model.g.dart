// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryModelAdapter extends TypeAdapter<HistoryModel> {
  @override
  final typeId = 2;

  @override
  HistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryModel(
      id: fields[0] as String,
      sourcePath: fields[1] as String,
      outputPath: fields[2] as String,
      date: fields[3] as DateTime,
      profileName: fields[4] as String,
      processingMillis: (fields[5] as num).toInt(),
      status: (fields[6] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourcePath)
      ..writeByte(2)
      ..write(obj.outputPath)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.profileName)
      ..writeByte(5)
      ..write(obj.processingMillis)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
