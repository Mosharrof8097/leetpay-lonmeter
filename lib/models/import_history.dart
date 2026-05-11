import 'package:hive/hive.dart';

part 'import_history.g.dart';

@HiveType(typeId: 3)
class ImportHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final DateTime importDate;

  @HiveField(3)
  final String platformId;

  @HiveField(4)
  final int totalRowsProcessed;

  @HiveField(5)
  final double totalBruttoCalculated;

  ImportHistoryModel({
    required this.id,
    required this.fileName,
    required this.importDate,
    required this.platformId,
    required this.totalRowsProcessed,
    required this.totalBruttoCalculated,
  });
}
