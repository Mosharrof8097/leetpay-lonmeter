import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../models/earnings_entry.dart';

final commissionRatesProvider = StateNotifierProvider<CommissionRatesNotifier, List<double>>((ref) {
  return CommissionRatesNotifier();
});

class CommissionRatesNotifier extends StateNotifier<List<double>> {
  CommissionRatesNotifier() : super(DatabaseService.getCommissionRates());

  Future<void> addRate(double rate) async {
    if (state.contains(rate)) return;
    final newState = [...state, rate]..sort();
    state = newState;
    await DatabaseService.saveCommissionRates(state);
  }

  Future<void> removeRate(double rate) async {
    if (state.length <= 1) return;
    state = state.where((r) => r != rate).toList();
    await DatabaseService.saveCommissionRates(state);
  }
}

final platformSettingsProvider = StateNotifierProvider<PlatformSettingsNotifier, List<PlatformModel>>((ref) {
  return PlatformSettingsNotifier();
});

class PlatformSettingsNotifier extends StateNotifier<List<PlatformModel>> {
  PlatformSettingsNotifier() : super(DatabaseService.getAllPlatforms());

  Future<void> addPlatform(String name) async {
    final id = name.toLowerCase().replaceAll(' ', '_');
    if (state.any((p) => p.id == id)) return;
    
    final platform = PlatformModel(id: id, name: name);
    await DatabaseService.savePlatform(platform);
    state = [...state, platform];
  }

  Future<void> updatePlatform(String id, String newName) async {
    final idx = state.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    
    final platform = state[idx];
    if (platform.isLocked ?? false) return;
    
    platform.name = newName;
    await DatabaseService.savePlatform(platform);
    state = [...state];
  }

  Future<void> deletePlatform(String id) async {
    final platform = state.firstWhere((p) => p.id == id);
    if (platform.isLocked ?? false) return;
    
    await DatabaseService.deletePlatform(id);
    state = state.where((p) => p.id != id).toList();
  }
}

final companyNameProvider = StateNotifierProvider<CompanyNameNotifier, String>((ref) {
  return CompanyNameNotifier();
});

class CompanyNameNotifier extends StateNotifier<String> {
  CompanyNameNotifier() : super(DatabaseService.getCompanyName());

  Future<void> updateName(String newName) async {
    // 1. Update local Hive
    await DatabaseService.saveSetting('companyName', newName);
    
    // 2. Update state to notify UI listeners immediately
    state = newName;

    // 3. Sync with Supabase (if online)
    try {
      await SupabaseService.updateSettings({'company_name': newName});
    } catch (e) {
      print('Supabase settings sync failed: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      final settings = await SupabaseService.getSettings();
      final newName = settings['company_name'] as String?;
      if (newName != null && newName.isNotEmpty) {
        await DatabaseService.saveSetting('companyName', newName);
        state = newName;
      }
    } catch (e) {
      print('Failed to refresh settings from Supabase: $e');
    }
  }
}
