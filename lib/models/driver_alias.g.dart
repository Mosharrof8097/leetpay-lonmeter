// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_alias.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DriverAliasModelAdapter extends TypeAdapter<DriverAliasModel> {
  @override
  final int typeId = 4;

  @override
  DriverAliasModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverAliasModel(
      aliasName: fields[0] as String,
      driverId: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DriverAliasModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.aliasName)
      ..writeByte(1)
      ..write(obj.driverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverAliasModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
