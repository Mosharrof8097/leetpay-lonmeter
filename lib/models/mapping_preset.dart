import 'package:hive/hive.dart';

@HiveType(typeId: 6)
class MappingPreset extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final Map<String, int> mapping; // Field Name -> Column Index

  @HiveField(3)
  final String platformId;

  MappingPreset({
    required this.id,
    required this.name,
    required this.mapping,
    required this.platformId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mapping': mapping,
    'platform_id': platformId,
  };

  factory MappingPreset.fromMap(Map<String, dynamic> map) => MappingPreset(
    id: map['id'] as String,
    name: map['name'] as String,
    mapping: Map<String, int>.from(map['mapping']),
    platformId: map['platform_id'] as String,
  );
}

// Manual Adapter since build_runner is not generating the file correctly
class MappingPresetAdapter extends TypeAdapter<MappingPreset> {
  @override
  final int typeId = 6;

  @override
  MappingPreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MappingPreset(
      id: fields[0] as String,
      name: fields[1] as String,
      mapping: (fields[2] as Map).cast<String, int>(),
      platformId: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MappingPreset obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.mapping)
      ..writeByte(3)
      ..write(obj.platformId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MappingPresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
