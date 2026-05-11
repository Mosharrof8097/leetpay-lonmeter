import 'package:hive/hive.dart';

part 'driver.g.dart';

@HiveType(typeId: 0)
class Driver extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double commissionRate;

  @HiveField(3)
  bool isActive;

  Driver({
    required this.id,
    required this.name,
    required this.commissionRate,
    this.isActive = true,
  });

  String get commissionLabel => '${(commissionRate * 100).toStringAsFixed(0)}%';

  Driver copyWith({
    String? id,
    String? name,
    double? commissionRate,
    bool? isActive,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'commissionRate': commissionRate,
    'isActive': isActive,
  };

  factory Driver.fromMap(Map<String, dynamic> map) => Driver(
    id: map['id'] as String,
    name: map['name'] as String,
    commissionRate: (map['commissionRate'] as num).toDouble(),
    isActive: map['isActive'] as bool? ?? true,
  );
}