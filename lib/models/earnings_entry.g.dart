// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      appliedPercentage: fields[12] as double?,
      platformFee: fields[13] as double?,
      reference: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EarningsEntry obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.socialFees)
      ..writeByte(12)
      ..write(obj.appliedPercentage)
      ..writeByte(13)
      ..write(obj.platformFee)
      ..writeByte(14)
      ..write(obj.reference);
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
