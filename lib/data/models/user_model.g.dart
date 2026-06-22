// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final typeId = 4;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String,
      googleDisplayName: fields[2] as String?,
      googlePhotoUrl: fields[3] as String?,
      displayNameOverride: fields[4] as String?,
      photoPath: fields[5] as String?,
      phone: fields[6] as String?,
      company: fields[7] as String?,
      role: fields[8] as String?,
      signedInAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.googleDisplayName)
      ..writeByte(3)
      ..write(obj.googlePhotoUrl)
      ..writeByte(4)
      ..write(obj.displayNameOverride)
      ..writeByte(5)
      ..write(obj.photoPath)
      ..writeByte(6)
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.company)
      ..writeByte(8)
      ..write(obj.role)
      ..writeByte(9)
      ..write(obj.signedInAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
