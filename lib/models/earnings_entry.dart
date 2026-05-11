import 'package:hive/hive.dart';

part 'earnings_entry.g.dart';

@HiveType(typeId: 2)
class PlatformModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  bool? isLocked;

  PlatformModel({
    required this.id,
    required this.name,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isLocked': isLocked,
  };

  factory PlatformModel.fromMap(Map<String, dynamic> map) => PlatformModel(
    id: map['id'] as String,
    name: map['name'] as String,
    isLocked: map['isLocked'] as bool? ?? false,
  );
}

@HiveType(typeId: 1)
class EarningsEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String driverId;

  @HiveField(2)
  final int weekNumber;

  @HiveField(3)
  final int month;

  @HiveField(4)
  final int year;

  @HiveField(5)
  final String platformId; // Changed from enum to String

  @HiveField(6)
  double bruttoAmount;

  @HiveField(7)
  double nettoAmount;

  @HiveField(8)
  double moms6;

  @HiveField(9)
  double dricks;

  @HiveField(10)
  double? uberBrutto;

  @HiveField(11)
  double? socialFees;

  @HiveField(12)
  double? appliedPercentage;

  @HiveField(13)
  double? platformFee;

  EarningsEntry({
    required this.id,
    required this.driverId,
    required this.weekNumber,
    required this.month,
    required this.year,
    required this.platformId,
    this.bruttoAmount = 0.0,
    this.nettoAmount = 0.0,
    this.moms6 = 0.0,
    this.dricks = 0.0,
    this.uberBrutto = 0.0,
    this.socialFees = 0.0,
    this.appliedPercentage,
    this.platformFee = 0.0,
  });

  EarningsEntry copyWith({
    String? id,
    String? driverId,
    int? weekNumber,
    int? month,
    int? year,
    String? platformId,
    double? bruttoAmount,
    double? nettoAmount,
    double? moms6,
    double? dricks,
    double? uberBrutto,
    double? socialFees,
    double? appliedPercentage,
  }) {
    return EarningsEntry(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      weekNumber: weekNumber ?? this.weekNumber,
      month: month ?? this.month,
      year: year ?? this.year,
      platformId: platformId ?? this.platformId,
      bruttoAmount: bruttoAmount ?? this.bruttoAmount,
      nettoAmount: nettoAmount ?? this.nettoAmount,
      moms6: moms6 ?? this.moms6,
      dricks: dricks ?? this.dricks,
      uberBrutto: uberBrutto ?? this.uberBrutto,
      socialFees: socialFees ?? this.socialFees,
      appliedPercentage: appliedPercentage ?? this.appliedPercentage,
      platformFee: platformFee ?? this.platformFee,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'driverId': driverId,
    'weekNumber': weekNumber,
    'month': month,
    'year': year,
    'platformId': platformId,
    'bruttoAmount': bruttoAmount,
    'nettoAmount': nettoAmount,
    'moms6': moms6,
    'dricks': dricks,
    'uberBrutto': uberBrutto,
    'socialFees': socialFees,
    'applied_percentage': appliedPercentage,
    'platform_fee': platformFee,
  };

  factory EarningsEntry.fromMap(Map<String, dynamic> map) => EarningsEntry(
    id: map['id'] as String,
    driverId: map['driverId'] as String,
    weekNumber: map['weekNumber'] as int,
    month: map['month'] as int,
    year: map['year'] as int,
    platformId: map['platformId'] as String? ?? 'uber',
    bruttoAmount: (map['bruttoAmount'] as num).toDouble(),
    nettoAmount: (map['nettoAmount'] as num).toDouble(),
    moms6: (map['moms6'] as num).toDouble(),
    dricks: (map['dricks'] as num).toDouble(),
    uberBrutto: (map['uberBrutto'] as num?)?.toDouble(),
    socialFees: (map['socialFees'] as num?)?.toDouble(),
    appliedPercentage: (map['applied_percentage'] as num?)?.toDouble(),
    platformFee: (map['platform_fee'] as num?)?.toDouble() ?? 0.0,
  );
}