import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bolt_trip.dart';
import '../services/fleet_api_service.dart';
import 'auth_provider.dart';

class BoltTripsNotifier extends StateNotifier<AsyncValue<List<BoltTrip>>> {
  final Ref ref;
  BoltTripsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    // If we're already loading, don't trigger again unless forced
    if (state is AsyncLoading && state.hasValue) return;
    
    state = const AsyncValue.loading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Step 1: Fetch from unified table
      var query = Supabase.instance.client
          .from('earnings_raw')
          .select()
          .eq('owner_id', user.id);

      // Step 2: Security Filter - If not admin, only show trips matching driver's name
      // In this app, we match by driver_name for now as a simple way to filter
      final isDriver = user.userMetadata?['role'] == 'driver';
      final driverName = user.userMetadata?['name']?.toString().toLowerCase().trim();

      if (isDriver && driverName != null) {
        query = query.ilike('driver_name', '%$driverName%');
      }

      final response = await query
          .eq('platform', 'bolt')
          .order('date', ascending: false);
      
      final trips = (response as List).map((json) => BoltTrip.fromJson(json)).toList();
      state = AsyncValue.data(trips);
    } catch (e, st) {
      debugPrint('BoltTrips: Error loading trips: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncNow() async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      debugPrint('BoltTrips: Triggering Edge Function sync...');
      await FleetApiService.triggerSync();
      debugPrint('BoltTrips: Sync completed');
      
      await loadTrips();
    } catch (e, st) {
      debugPrint('BoltTrips: Sync failed: $e');
      state = AsyncValue.error(e, st);
      // Optional: revert to previous state after showing error
    }
  }
}

final boltTripsProvider = StateNotifierProvider<BoltTripsNotifier, AsyncValue<List<BoltTrip>>>((ref) {
  return BoltTripsNotifier(ref);
});

/// Summary Provider for the Dashboard
final boltTotalRevenueProvider = Provider<double>((ref) {
  final tripsAsync = ref.watch(boltTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) => trips.fold(0.0, (sum, item) => sum + item.priceTotal),
    orElse: () => 0.0,
  );
});

final boltTotalTaxesProvider = Provider<double>((ref) {
  final tripsAsync = ref.watch(boltTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) => trips.fold(0.0, (sum, item) => sum + (item.priceTotal - item.netEarnings)),
    orElse: () => 0.0,
  );
});

final boltTotalNetPayoutProvider = Provider<double>((ref) {
  final tripsAsync = ref.watch(boltTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) => trips.fold(0.0, (sum, item) => sum + item.netEarnings),
    orElse: () => 0.0,
  );
});

final boltDriverPayoutsProvider = Provider<Map<String, double>>((ref) {
  final tripsAsync = ref.watch(boltTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) {
      final Map<String, double> payouts = {};
      for (var trip in trips) {
        final name = trip.driverName ?? 'Unknown Driver';
        payouts[name] = (payouts[name] ?? 0.0) + trip.netEarnings;
      }
      return payouts;
    },
    orElse: () => {},
  );
});
