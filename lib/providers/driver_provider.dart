import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../services/supabase_service.dart';
import 'payroll_provider.dart';
import 'auth_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class DriverNotifier extends StateNotifier<List<Driver>> {
  final Ref ref;
  DriverNotifier(this.ref) : super([]) { 
    _init();
  }

  void _init() {
    // Reload when auth state changes
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
    state = await SupabaseService.getDrivers(); 
  }

  Future<void> addDriver(String name, double commissionRate) async {
    final driver = Driver(
      id: _uuid.v4(), 
      name: name, 
      commissionRate: commissionRate
    );
    await SupabaseService.upsertDriver(driver);
    await _load();
    ref.invalidate(monthlyPayrollProvider);
  }

  Future<void> updateDriver(Driver driver) async {
    await SupabaseService.upsertDriver(driver);
    await _load();
    ref.invalidate(monthlyPayrollProvider);
  }

  Future<void> deleteDriver(String id) async {
    await SupabaseService.deleteDriver(id);
    await _load();
    ref.invalidate(monthlyPayrollProvider);
  }

  Future<void> toggleActive(String id) async {
    final driver = state.firstWhere((d) => d.id == id);
    final updated = driver.copyWith(isActive: !driver.isActive);
    await SupabaseService.upsertDriver(updated);
    await _load();
    ref.invalidate(monthlyPayrollProvider);
  }

  Future<void> refresh() => _load();
}

final driverProvider = StateNotifierProvider<DriverNotifier, List<Driver>>((ref) {
  return DriverNotifier(ref);
});

final activeDriversProvider = Provider<List<Driver>>((ref) {
  return ref.watch(driverProvider).where((d) => d.isActive).toList();
});