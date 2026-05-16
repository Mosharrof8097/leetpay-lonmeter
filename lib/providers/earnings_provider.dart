import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earnings_entry.dart';
import '../services/supabase_service.dart';
import '../services/calculation_service.dart';
import 'payroll_provider.dart';
import 'auth_provider.dart';
import 'driver_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class EarningsNotifier extends StateNotifier<List<EarningsEntry>> {
  final Ref ref;
  EarningsNotifier(this.ref) : super([]) { 
    _init();
  }

  void _init() {
    ref.listen(authStateProvider, (previous, next) {
      if (next.value?.session?.user != null) {
        _load();
      } else {
        state = [];
      }
    });
    _load();
  }

  Future<void> _load() async { 
    final rawList = await SupabaseService.getEarnings();
    state = rawList
        .cast<Map<String, dynamic>>()
        .map((row) => EarningsEntry.fromSupabase(row))
        .toList();
  }

  Future<void> addEarnings({
    required String driverId,
    required int weekNumber,
    required int month,
    required int year,
    required String platformId,
    required double bruttoAmount,
    double dricks = 0,
    double uberBrutto = 0,
    double platformFee = 0,
  }) async {
    try {
      final netto = CalculationService.calculateNetEarnings(bruttoAmount, feeAmount: platformFee);
      final moms = CalculationService.calculateMoms(bruttoAmount);
      final socialFees = CalculationService.calculateSocialFees(bruttoAmount);
      
      // Get driver's current percentage for snapshotting
      final drivers = ref.read(driverProvider);
      final driver = drivers.firstWhere((d) => d.id == driverId);
      final appliedRate = driver.commissionRate;
      
      final entry = EarningsEntry(
        id: _uuid.v4(),
        driverId: driverId,
        weekNumber: weekNumber,
        month: month,
        year: year,
        platformId: platformId,
        bruttoAmount: bruttoAmount,
        nettoAmount: netto,
        moms6: moms,
        dricks: dricks,
        uberBrutto: uberBrutto,
        socialFees: socialFees,
        appliedPercentage: appliedRate,
        platformFee: platformFee,
      );
      await SupabaseService.saveEarnings(entry);
      await _load();
      ref.invalidate(monthlyPayrollProvider);
    } catch (e) {
      debugPrint('Add Earnings Failed: $e');
      rethrow;
    }
  }

  Future<void> updateEarnings(EarningsEntry entry) async {
    await SupabaseService.saveEarnings(entry);
    await _load();
    ref.invalidate(monthlyPayrollProvider);
  }

  Future<void> deleteEarnings(String id) async {
    await SupabaseService.client.from('earnings').delete().eq('id', id);
    await _load();
    ref.invalidate(monthlyPayrollProvider);
  }

  Future<void> refresh() {
    ref.invalidate(monthlyPayrollProvider);
    return _load();
  }
}

final earningsProvider = StateNotifierProvider<EarningsNotifier, List<EarningsEntry>>((ref) {
  return EarningsNotifier(ref);
});

final driverEarningsProvider = Provider.family<List<EarningsEntry>, String>((ref, driverId) {
  return ref.watch(earningsProvider).where((e) => e.driverId == driverId).toList();
});

final monthEarningsProvider = Provider.family<List<EarningsEntry>, ({int month, int year})>((ref, params) {
  return ref.watch(earningsProvider)
      .where((e) => e.month == params.month && e.year == params.year)
      .toList();
});

final driverMonthEarningsProvider = Provider.family<List<EarningsEntry>, ({String driverId, int month, int year})>((ref, params) {
  return ref.watch(earningsProvider)
      .where((e) => e.driverId == params.driverId && e.month == params.month && e.year == params.year)
      .toList();
});