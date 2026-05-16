import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver.dart';
import '../providers/driver_provider.dart';

/// Manages the selected date range for the dashboard
final dashboardDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0),
  );
});

/// Fetches raw earnings from Supabase for the selected range
final rawEarningsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final range = ref.watch(dashboardDateRangeProvider);
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  final response = await supabase
      .from('earnings_raw')
      .select()
      .eq('owner_id', userId)
      .gte('date', range.start.toIso8601String().split('T')[0])
      .lte('date', range.end.toIso8601String().split('T')[0]);
  
  final data = (response as List).cast<Map<String, dynamic>>();
  debugPrint("DBA_DEBUG: Fetched ${data.length} earnings rows. Sample: ${data.isNotEmpty ? data.first : 'Empty'}");
  return data;
});

/// Computed data for the dashboard based on the selected date range
final dashboardDataProvider = Provider<DashboardMetrics>((ref) {
  final range = ref.watch(dashboardDateRangeProvider);
  final earningsAsync = ref.watch(rawEarningsProvider);
  final drivers = ref.watch(driverProvider);

  final List<Map<String, dynamic>> earnings = earningsAsync.value ?? [];

  double totalGross = 0;
  double totalNet = 0;
  final Map<String, double> platformGross = {};
  final Map<String, double> driverGross = {};

  for (final e in earnings) {
    // Null-safe: use normalized field names from earnings_raw
    final double brutto = (e['brutto_amount'] as num? ?? 0).toDouble();
    final double net = (e['net_amount'] as num? ?? 0).toDouble();
    final String platform = (e['platform'] as String? ?? 'other').toLowerCase();
    final String? driverId = e['driver_id'] as String?;

    totalGross += brutto;
    totalNet += net;
    platformGross[platform] = (platformGross[platform] ?? 0) + brutto;

    if (driverId != null && driverId.isNotEmpty) {
      driverGross[driverId] = (driverGross[driverId] ?? 0) + brutto;
    }
  }

  debugPrint("DBA_DEBUG: Dashboard → rows=${earnings.length} totalGross=$totalGross drivers=${driverGross.length}");

  // Swedish Tax Calculation (6% Moms factor = 0.0566 of gross)
  final totalMoms = totalGross * 0.0566;
  final totalFees = totalGross - totalMoms - totalNet;
  final netRevenue = totalNet;

  return DashboardMetrics(
    range: range,
    totalGross: totalGross,
    totalTax: totalMoms,
    totalFees: totalFees,
    netRevenue: netRevenue,
    activeDriversCount: drivers.where((d) => d.isActive).length,
    platformGross: platformGross,
    driverGross: driverGross,
    drivers: drivers,
  );
});

class DashboardMetrics {
  final DateTimeRange range;
  final double totalGross;
  final double totalTax;
  final double totalFees;
  final double netRevenue;
  final int activeDriversCount;
  final Map<String, double> platformGross;
  final Map<String, double> driverGross;
  final List<Driver> drivers;

  DashboardMetrics({
    required this.range,
    required this.totalGross,
    required this.totalTax,
    required this.totalFees,
    required this.netRevenue,
    required this.activeDriversCount,
    required this.platformGross,
    required this.driverGross,
    required this.drivers,
  });
}
