class PlatformConfig {
  final String? id;
  final String userId;
  final String platformName;
  final String clientId;
  final String clientSecret;
  final String fleetId;
  final double platformFeePercent;
  final double driverSharePercent;
  final double taxPercent;
  final double holidayPayPercent;
  final double pensionPercent;
  final bool isActive;
  final DateTime? lastSyncAt;

  PlatformConfig({
    this.id,
    required this.userId,
    this.platformName = 'bolt',
    required this.clientId,
    required this.clientSecret,
    required this.fleetId,
    this.platformFeePercent = 20.0,
    this.driverSharePercent = 45.0,
    this.taxPercent = 5.66,
    this.holidayPayPercent = 12.0,
    this.pensionPercent = 4.5,
    this.isActive = true,
    this.lastSyncAt,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      id: json['id'],
      userId: json['user_id'],
      platformName: json['platform_name'] ?? 'bolt',
      clientId: json['client_id'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      fleetId: json['fleet_id'] ?? '',
      platformFeePercent: (json['platform_fee_percent'] as num?)?.toDouble() ?? 20.0,
      driverSharePercent: (json['driver_share_percent'] as num?)?.toDouble() ?? 45.0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 5.66,
      holidayPayPercent: (json['holiday_pay_percent'] as num?)?.toDouble() ?? 12.0,
      pensionPercent: (json['pension_percent'] as num?)?.toDouble() ?? 4.5,
      isActive: json['is_active'] ?? true,
      lastSyncAt: json['last_sync_at'] != null ? DateTime.parse(json['last_sync_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'platform_name': platformName,
      'client_id': clientId,
      'client_secret': clientSecret,
      'fleet_id': fleetId,
      'platform_fee_percent': platformFeePercent,
      'driver_share_percent': driverSharePercent,
      'tax_percent': taxPercent,
      'holiday_pay_percent': holidayPayPercent,
      'pension_percent': pensionPercent,
      'is_active': isActive,
    };
  }

  PlatformConfig copyWith({
    String? clientId,
    String? clientSecret,
    String? fleetId,
    double? platformFeePercent,
    double? driverSharePercent,
    double? taxPercent,
    double? holidayPayPercent,
    double? pensionPercent,
    bool? isActive,
  }) {
    return PlatformConfig(
      id: id,
      userId: userId,
      platformName: platformName,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      fleetId: fleetId ?? this.fleetId,
      platformFeePercent: platformFeePercent ?? this.platformFeePercent,
      driverSharePercent: driverSharePercent ?? this.driverSharePercent,
      taxPercent: taxPercent ?? this.taxPercent,
      holidayPayPercent: holidayPayPercent ?? this.holidayPayPercent,
      pensionPercent: pensionPercent ?? this.pensionPercent,
      isActive: isActive ?? this.isActive,
      lastSyncAt: lastSyncAt,
    );
  }
}
