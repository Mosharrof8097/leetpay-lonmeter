import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bolt_trip.dart';
import '../services/fleet_api_service.dart';

class CompanyTripsNotifier extends StateNotifier<AsyncValue<List<BoltTrip>>> {
  final Ref ref;
  CompanyTripsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchTrips();
  }

  Future<void> fetchTrips() async {
    state = const AsyncValue.loading();
    try {
      final trips = await FleetApiService.getSyncedTrips();
      state = AsyncValue.data(trips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncBoltData() async {
    // 1. Set loading state while keeping existing data
    state = AsyncValue.data(state.value ?? []);
    
    try {
      // 2. Trigger the sync
      await FleetApiService.triggerSync();
      
      // 3. Invalidate to force a clean reload of everything
      await fetchTrips();
      
      // Also invalidate related summaries to ensure UI updates across the app
      ref.invalidate(companySummaryProvider);
      ref.invalidate(groupedByDriverProvider);
      ref.invalidate(driverSummariesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Main Provider for Company Trips
final companyTripsProvider = StateNotifierProvider<CompanyTripsNotifier, AsyncValue<List<BoltTrip>>>((ref) {
  return CompanyTripsNotifier(ref);
});

/// Company-wide Financial Summary
final companySummaryProvider = Provider<({double gross, double commission, double taxes, double net})>((ref) {
  final tripsAsync = ref.watch(companyTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) {
      double gross = 0;
      double commission = 0;
      double taxes = 0;
      double net = 0;
      for (var t in trips) {
        gross += t.priceTotal;
        commission += (t.priceTotal - t.netEarnings);
        taxes += (t.tax6Percent ?? 0.0) + (t.employerFee3142 ?? 0.0);
        net += (t.netPayoutToDriver ?? 0.0);
      }
      return (gross: gross, commission: commission, taxes: taxes, net: net);
    },
    orElse: () => (gross: 0.0, commission: 0.0, taxes: 0.0, net: 0.0),
  );
});

/// Grouped Trips by Driver
final groupedByDriverProvider = Provider<Map<String, List<BoltTrip>>>((ref) {
  final tripsAsync = ref.watch(companyTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) {
      final Map<String, List<BoltTrip>> grouped = {};
      for (var t in trips) {
        final name = t.driverName ?? 'Unknown Driver';
        grouped.putIfAbsent(name, () => []).add(t);
      }
      // Sort drivers alphabetically
      final sortedKeys = grouped.keys.toList()..sort();
      return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, grouped[k]!)));
    },
    orElse: () => {},
  );
});

/// Summary per Driver (Net Payout and Trip Count)
final driverSummariesProvider = Provider<Map<String, ({double net, int tripCount})>>((ref) {
  final grouped = ref.watch(groupedByDriverProvider);
  return grouped.map((name, trips) {
    final net = trips.fold(0.0, (sum, t) => sum + (t.netPayoutToDriver ?? 0.0));
    return MapEntry(name, (net: net, tripCount: trips.length));
  });
});
