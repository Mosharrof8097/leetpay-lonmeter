import 'package:hive/hive.dart';

part 'driver_alias.g.dart';

@HiveType(typeId: 4)
class DriverAliasModel extends HiveObject {
  @HiveField(0)
  final String aliasName; // The name as it appears in the file

  @HiveField(1)
  final String driverId; // The ID of the driver in our database

  DriverAliasModel({
    required this.aliasName,
    required this.driverId,
  });
}
