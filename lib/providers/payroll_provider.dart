import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monthly_payroll.dart';
import '../models/earnings_entry.dart';
import '../services/calculation_service.dart';
import 'driver_provider.dart';

/// Fetches unsettled raw earnings from Supabase for a specific period
final unsettledEarningsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({int month, int year})>((ref, params) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final startDate = DateTime(params.year, params.month, 1).toIso8601String().split('T')[0];
  final endDate = DateTime(params.year, params.month + 1, 0).toIso8601String().split('T')[0];

  final response = await supabase
      .from('earnings_raw')
      .select()
      .eq('owner_id', userId)
      .eq('is_settled', false) // Only unsettled data
      .gte('date', startDate)
      .lte('date', endDate);
  
  return (response as List).cast<Map<String, dynamic>>();
});

final monthlyPayrollProvider = Provider.family<List<MonthlyPayroll>, ({int month, int year})>((ref, params) {
  final drivers = ref.watch(driverProvider);
  final earningsAsync = ref.watch(unsettledEarningsProvider(params));
  
  final earnings = earningsAsync.value ?? [];
  final payrolls = <MonthlyPayroll>[];

  if (earnings.isEmpty) return [];

  // Group everything by driver_id
  final driverGroups = <String, List<Map<String, dynamic>>>{};
  for (final e in earnings) {
    final dId = (e['driver_id'] ?? 'unassigned').toString();
    driverGroups.putIfAbsent(dId, () => []).add(e);
  }

  // Process each driver group
  for (final driverId in driverGroups.keys) {
    final group = driverGroups[driverId]!;
    final driver = drivers.where((d) => d.id == driverId).firstOrNull;
    
    final String driverName = driver?.name ?? 'Unknown Driver ($driverId)';
    final double commissionRate = driver?.commissionRate ?? 0.43;

    // Convert raw entries to EarningsEntry models for the calculation engine
    final entries = group.map((e) {
      final brutto = (e['brutto_amount'] as num).toDouble();
      final netto = (e['net_amount'] as num).toDouble();
      final platformFee = brutto - netto;

      return EarningsEntry(
        id: e['id'],
        driverId: driverId,
        weekNumber: 0,
        month: params.month,
        year: params.year,
        platformId: e['platform'],
        bruttoAmount: brutto,
        nettoAmount: netto,
        moms6: CalculationService.calculateMoms(brutto),
        dricks: (e['dricks'] as num? ?? 0).toDouble(),
        socialFees: CalculationService.calculateSocialFees(brutto),
        appliedPercentage: commissionRate,
        platformFee: platformFee,
      );
    }).toList();

    payrolls.add(CalculationService.generateMonthlyPayroll(
      driverId: driverId,
      driverName: driverName,
      commissionRate: commissionRate,
      month: params.month,
      year: params.year,
      entries: entries,
      useLiveRate: true,
    ));
  }

  payrolls.sort((a, b) => a.driverName.toLowerCase().compareTo(b.driverName.toLowerCase()));
  return payrolls;
});

final driverPayrollProvider = Provider.family<MonthlyPayroll?, ({String driverId, int month, int year})>((ref, params) {
  final payrolls = ref.watch(monthlyPayrollProvider((month: params.month, year: params.year)));
  try {
    return payrolls.firstWhere((p) => p.driverId == params.driverId);
  } catch (_) {
    return null;
  }
});