import 'package:flutter/foundation.dart';
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

  @HiveField(4)
  String platform; // Map to platform_preference in DB

  @HiveField(5)
  double totalHolidaySaved;

  @HiveField(6)
  double totalPensionSaved;

  @HiveField(7)
  double totalTuitionSaved;

  @HiveField(8)
  String? phone;

  @HiveField(9)
  String? boltUuid;

  Driver({
    required this.id,
    required this.name,
    required this.commissionRate,
    this.isActive = true,
    this.platform = 'Bolt',
    this.totalHolidaySaved = 0.0,
    this.totalPensionSaved = 0.0,
    this.totalTuitionSaved = 0.0,
    this.phone,
    this.boltUuid,
  });

  String get commissionLabel => '${(commissionRate * 100).toStringAsFixed(0)}%';

  Driver copyWith({
    String? id,
    String? name,
    double? commissionRate,
    bool? isActive,
    String? platform,
    double? totalHolidaySaved,
    double? totalPensionSaved,
    double? totalTuitionSaved,
    String? phone,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      platform: platform ?? this.platform,
      totalHolidaySaved: totalHolidaySaved ?? this.totalHolidaySaved,
      totalPensionSaved: totalPensionSaved ?? this.totalPensionSaved,
      totalTuitionSaved: totalTuitionSaved ?? this.totalTuitionSaved,
      phone: phone ?? this.phone,
    );
  }

  // Used for Supabase (Snake Case)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'commission_rate': commissionRate,
    'platform_preference': platform,
    'holiday_savings': totalHolidaySaved,
    'pension_savings': totalPensionSaved,
    'tuition_savings': totalTuitionSaved,
    'phone': phone,
    'bolt_uuid': boltUuid,
  };

  factory Driver.fromJson(Map<String, dynamic> json) {
    try {
      return Driver(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Driver',
        commissionRate: (json['commission_rate'] as num? ?? 0.43).toDouble(),
        platform: json['platform_preference']?.toString() ?? 'Bolt',
        totalHolidaySaved: (json['holiday_savings'] as num? ?? 0.0).toDouble(),
        totalPensionSaved: (json['pension_savings'] as num? ?? 0.0).toDouble(),
        totalTuitionSaved: (json['tuition_savings'] as num? ?? 0.0).toDouble(),
        phone: json['phone']?.toString(),
        boltUuid: json['bolt_uuid']?.toString(),
        isActive: json['is_active'] == false ? false : true,
      );
    } catch (e) {
      debugPrint('DBA_DEBUG: Error parsing driver JSON: $e | Data: $json');
      // Return a dummy driver to avoid breaking the list, or rethrow
      return Driver(id: 'error', name: 'Parse Error', commissionRate: 0);
    }
  }

  // Keep compatibility with old code if needed
  Map<String, dynamic> toMap() => toJson();
  factory Driver.fromMap(Map<String, dynamic> map) => Driver.fromJson(map);
}