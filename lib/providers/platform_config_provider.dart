import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/platform_config.dart';

class PlatformConfigNotifier extends AsyncNotifier<PlatformConfig?> {
  final _supabase = Supabase.instance.client;

  @override
  FutureOr<PlatformConfig?> build() async {
    debugPrint('PlatformConfig: build() called');
    return _loadConfig();
  }

  Future<PlatformConfig?> _loadConfig() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('PlatformConfig: No authenticated user.');
      return null;
    }

    try {
      debugPrint('PlatformConfig: Fetching for user ${user.id}...');
      final data = await _supabase
          .from('platform_configs')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        final config = PlatformConfig.fromJson(data);
        debugPrint('PlatformConfig: Successfully loaded config for ${config.clientId}');
        return config;
      }
      
      debugPrint('PlatformConfig: No config row found in DB.');
      return null;
    } catch (e, st) {
      debugPrint('PlatformConfig: Error in _loadConfig: $e');
      // If table doesn't exist yet, return null instead of erroring out to keep UI clean
      if (e.toString().contains('42P01') || e.toString().contains('schema cache')) {
        return null;
      }
      return null; // Return null to stop loading state even on error
    }
  }

  Future<void> upsertConfig({
    required String clientId,
    required String clientSecret,
    required String fleetId,
    required double platformFeePercent,
    required double driverSharePercent,
    required double taxPercent,
    required double holidayPayPercent,
    required double pensionPercent,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('PlatformConfig: Cannot upsert, no user logged in.');
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final configMap = {
        'user_id': user.id,
        'client_id': clientId.trim(),
        'client_secret': clientSecret.trim(),
        'fleet_id': fleetId.trim(),
        'platform_name': 'bolt',
        'platform_fee_percent': platformFeePercent,
        'driver_share_percent': driverSharePercent,
        'tax_percent': taxPercent,
        'holiday_pay_percent': holidayPayPercent,
        'pension_percent': pensionPercent,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('PlatformConfig: Executing upsert in Supabase...');
      await _supabase.from('platform_configs').upsert(configMap, onConflict: 'user_id,platform_name');
      debugPrint('PlatformConfig: Upsert successful.');
      
      // Force a manual refresh
      ref.invalidateSelf();
      await future; 
      debugPrint('PlatformConfig: State refreshed successfully.');
    } catch (e, st) {
      debugPrint('PlatformConfig: Upsert failed: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final platformConfigProvider = AsyncNotifierProvider<PlatformConfigNotifier, PlatformConfig?>(() {
  return PlatformConfigNotifier();
});
