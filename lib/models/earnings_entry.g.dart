// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlatformModelAdapter extends TypeAdapter<PlatformModel> {
  @override
  final int typeId = 2;

  @override
  PlatformModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlatformModel(
      id: fields[0] as String,
      name: fields[1] as String,
      isLocked: fields[2] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, PlatformModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isLocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EarningsEntryAdapter extends TypeAdapter<EarningsEntry> {
  @override
  final int typeId = 1;

  @override
  EarningsEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EarningsEntry(
      id: fields[0] as String,
      driverId: fields[1] as String,
      weekNumber: fields[2] as int,
      month: fields[3] as int,
      year: fields[4] as int,
      platformId: fields[5] as String,
      bruttoAmount: fields[6] as double,
      nettoAmount: fields[7] as double,
      moms6: fields[8] as double,
      dricks: fields[9] as double,
      uberBrutto: fields[10] as double?,
      socialFees: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, EarningsEntry obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driverId)
      ..writeByte(2)
      ..write(obj.weekNumber)
      ..writeByte(3)
      ..write(obj.month)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.platformId)
      ..writeByte(6)
      ..write(obj.bruttoAmount)
      ..writeByte(7)
      ..write(obj.nettoAmount)
      ..writeByte(8)
      ..write(obj.moms6)
      ..writeByte(9)
      ..write(obj.dricks)
      ..writeByte(10)
      ..write(obj.uberBrutto)
      ..writeByte(11)
      ..write(obj.socialFees);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
