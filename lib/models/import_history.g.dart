// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImportHistoryModelAdapter extends TypeAdapter<ImportHistoryModel> {
  @override
  final int typeId = 3;

  @override
  ImportHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImportHistoryModel(
      id: fields[0] as String,
      fileName: fields[1] as String,
      importDate: fields[2] as DateTime,
      platformId: fields[3] as String,
      totalRowsProcessed: fields[4] as int,
      totalBruttoCalculated: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ImportHistoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.importDate)
      ..writeByte(3)
      ..write(obj.platformId)
      ..writeByte(4)
      ..write(obj.totalRowsProcessed)
      ..writeByte(5)
      ..write(obj.totalBruttoCalculated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
