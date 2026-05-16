import "package:flutter/foundation.dart";
import 'package:uuid/uuid.dart';

class BoltTrip {
  final String? id;
  final String orderReference;
  final String? driverName;
  final String? driverUuid;
  final String? vehicleLicensePlate;
  final DateTime? orderCreatedTimestamp;
  final String? orderStatus;
  final double priceTotal;
  final double netEarnings;
  final double? tax6Percent;
  final double? employerFee3142;
  final double? netPayoutToDriver;
  final double dricks;
  final Map<String, dynamic>? rawData;
  final String source;
  final DateTime? createdAt;
  final String? userId;

  BoltTrip({
    this.id,
    required this.orderReference,
    this.driverName,
    this.driverUuid,
    this.vehicleLicensePlate,
    this.orderCreatedTimestamp,
    this.orderStatus,
    required this.priceTotal,
    required this.netEarnings,
    this.tax6Percent,
    this.employerFee3142,
    this.netPayoutToDriver,
    this.dricks = 0.0,
    this.rawData,
    this.source = 'Bolt',
    this.createdAt,
    this.userId,
  });

  factory BoltTrip.fromJson(Map<String, dynamic> json) {
    final rawData = json['raw_data'] as Map<String, dynamic>? ?? {};

    // 1. Try to find the price in various possible locations
    double priceTotal = 0.0;
    double netEarnings = 0.0;
    double tips = 0.0;

    // Direct fields (unified table format or simple API)
    priceTotal = (json["brutto_amount"] as num?)?.toDouble() ?? 
                 (json["price_total"] as num?)?.toDouble() ?? 
                 (json["total_price"] as num?)?.toDouble() ??
                 (json["amount"] as num?)?.toDouble() ?? 0.0;
    
    netEarnings = (json["net_amount"] as num?)?.toDouble() ?? 
                  (json["net_earnings"] as num?)?.toDouble() ?? 
                  (json["net_payout"] as num?)?.toDouble() ?? 0.0;

    tips = (json["dricks"] as num?)?.toDouble() ?? 
           (json["tip"] as num?)?.toDouble() ?? 
           (json["tips"] as num?)?.toDouble() ?? 
           (json["tip_amount"] as num?)?.toDouble() ??
           (json["client_tip"] as num?)?.toDouble() ?? 
           (rawData["dricks"] as num?)?.toDouble() ?? 
           (rawData["tip"] as num?)?.toDouble() ?? 
           (rawData["client_tip"] as num?)?.toDouble() ?? 0.0;
    
    // Nested 'order_price' (common in Bolt API)
    if (json['order_price'] != null && json['order_price'] is Map) {
      final op = json['order_price'] as Map<String, dynamic>;
      if (priceTotal == 0) priceTotal = (op['ride_price'] as num?)?.toDouble() ?? 0.0;
      if (priceTotal == 0) priceTotal = (op['total_price'] as num?)?.toDouble() ?? 0.0;
      if (priceTotal == 0) priceTotal = (op['amount'] as num?)?.toDouble() ?? 0.0;
      if (priceTotal == 0) priceTotal = (op['price'] as num?)?.toDouble() ?? 0.0;
      
      if (netEarnings == 0) netEarnings = (op['net_earnings'] as num?)?.toDouble() ?? 0.0;
      if (netEarnings == 0) netEarnings = (op['net_payout'] as num?)?.toDouble() ?? 0.0;
      
      if (tips == 0) {
        tips = (op['tip'] as num?)?.toDouble() ?? 
               (op['tips'] as num?)?.toDouble() ?? 
               (op['tip_amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Nested 'price' object
    if (json['price'] != null && json['price'] is Map) {
      final p = json['price'] as Map<String, dynamic>;
      if (priceTotal == 0) priceTotal = (p['amount'] as num?)?.toDouble() ?? 0.0;
    }

    // Fallback logic
    if (netEarnings == 0) netEarnings = priceTotal * 0.8; 
    
    final double tax6 = (json['moms_amount'] as num?)?.toDouble() ?? 
                       (json['tax_6_percent'] as num?)?.toDouble() ?? (priceTotal * 0.0566);
                       
    final double fee3142 = (json['employer_fee_31_42'] as num?)?.toDouble() ?? (netEarnings * 0.3142);
    final double payout = (json['net_payout_to_driver'] as num?)?.toDouble() ?? (netEarnings - fee3142);

    // Date parsing
    DateTime? timestamp;
    if (json['date'] != null) {
      timestamp = DateTime.tryParse(json['date'].toString());
    } else if (json['order_created_timestamp'] != null) {
      timestamp = DateTime.fromMillisecondsSinceEpoch((json['order_created_timestamp'] as int) * 1000);
    }

    return BoltTrip(
      id: json['id'],
      orderReference: json['reference']?.toString() ?? json['order_reference']?.toString() ?? rawData['order_reference']?.toString() ?? '',
      driverName: json['driver_name'],
      driverUuid: json['driver_id']?.toString() ?? json['driver_uuid']?.toString(),
      vehicleLicensePlate: json['vehicle_license_plate'] ?? rawData['vehicle_license_plate'],
      orderCreatedTimestamp: timestamp,
      orderStatus: json['order_status'] ?? json['status'] ?? json['state'] ?? rawData['order_status'] ?? rawData['status'] ?? rawData['state'] ?? 'Completed',
      priceTotal: priceTotal,
      netEarnings: netEarnings,
      tax6Percent: tax6,
      employerFee3142: fee3142,
      netPayoutToDriver: payout,
      dricks: tips,
      rawData: json,
      source: json['source'] ?? 'Bolt',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_reference': orderReference,
      'driver_name': driverName,
      'vehicle_license_plate': vehicleLicensePlate,
      'order_created_timestamp': orderCreatedTimestamp?.millisecondsSinceEpoch,
      'order_status': orderStatus,
      'price_total': priceTotal,
      'net_earnings': netEarnings,
      'tax_6_percent': tax6Percent,
      'employer_fee_31_42': employerFee3142,
      'net_payout_to_driver': netPayoutToDriver,
      'dricks': dricks,
      'raw_data': rawData,
      'source': source,
      'user_id': userId,
    };
  }
}
