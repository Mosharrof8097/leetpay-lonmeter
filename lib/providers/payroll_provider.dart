import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_payroll.dart';
import '../models/earnings_entry.dart';
import '../services/calculation_service.dart';
import 'driver_provider.dart';
import 'earnings_provider.dart';

final monthlyPayrollProvider = Provider.family<List<MonthlyPayroll>, ({int month, int year})>((ref, params) {
  final drivers = ref.watch(driverProvider);
  final allEarnings = ref.watch(earningsProvider);
  final payrolls = <MonthlyPayroll>[];

  // 1. Filter earnings for the selected period
  final periodEarnings = allEarnings
      .where((e) => e.month == params.month && e.year == params.year)
      .toList();

  if (periodEarnings.isEmpty) return [];

  // 2. Group earnings by driverId
  final earningsByDriver = <String, List<EarningsEntry>>{};
  for (final e in periodEarnings) {
    earningsByDriver.putIfAbsent(e.driverId, () => []).add(e);
  }

  // 3. Process each driver group
  for (final driverId in earningsByDriver.keys) {
    final entries = earningsByDriver[driverId]!;
    
    // Find driver info if available
    final driver = drivers.where((d) => d.id == driverId).firstOrNull;
    
    // Use fallback info for deleted drivers to maintain historical accuracy
    final driverName = driver?.name ?? 'Deleted Driver (${driverId.substring(0, 8)})';
    final commissionRate = driver?.commissionRate ?? 0.43;

    payrolls.add(CalculationService.generateMonthlyPayroll(
      driverId: driverId,
      driverName: driverName,
      commissionRate: commissionRate,
      month: params.month,
      year: params.year,
      entries: entries,
      useLiveRate: true, // Force use of live rate for the overview
    ));
  }

  // Sort by name for a consistent UI
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

// Dashboard summary providers
final totalRevenueProvider = Provider.family<double, ({int month, int year})>((ref, params) {
  final payrolls = ref.watch(monthlyPayrollProvider(params));
  return payrolls.fold<double>(0, (sum, p) => sum + p.totalBrutto);
});

final avgCommissionProvider = Provider.family<double, ({int month, int year})>((ref, params) {
  final payrolls = ref.watch(monthlyPayrollProvider(params));
  if (payrolls.isEmpty) return 0;
  // Use the actual commissionRate instead of effectiveRate (which includes social fees)
  final totalRate = payrolls.fold<double>(0, (sum, p) => sum + p.commissionRate);
  return totalRate / payrolls.length;
});

final totalProfitProvider = Provider.family<double, ({int month, int year})>((ref, params) {
  final payrolls = ref.watch(monthlyPayrollProvider(params));
  return payrolls.fold<double>(0, (sum, p) => sum + p.netProfit);
});

final avgProfitMarginProvider = Provider.family<double, ({int month, int year})>((ref, params) {
  final payrolls = ref.watch(monthlyPayrollProvider(params));
  if (payrolls.isEmpty) return 0;
  final totalMargin = payrolls.fold<double>(0, (sum, p) => sum + p.profitMargin);
  return totalMargin / payrolls.length;
});