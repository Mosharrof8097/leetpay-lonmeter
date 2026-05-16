import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver.dart';
import '../models/monthly_payroll.dart';

class SupabaseService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  // Compatibility getter for older code
  static SupabaseClient get client => _supabase;

  // Actual initialization
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://fglwkctadckygvvrpgqe.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnbHdrY3RhZGNreWd2dnJwZ3FlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxODg1NzEsImV4cCI6MjA5Mzc2NDU3MX0.PNiiQBh5XyEeLTNipY4EyNsWT8nYxiReLJA4VAD0IF4',
    );
  }
  static Future<void> migrateFromHive() async {}

  // ==========================================
  // ১. ড্রাইভার ম্যানেজমেন্ট (Drivers)
  // ==========================================
  
  static Future<List<Driver>> fetchDrivers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('owner_id', userId)
          .order('name');

      debugPrint('DBA_DEBUG: Successfully fetched ${response.length} drivers');
      return response.map((data) => Driver.fromJson(data)).toList();
    } catch (e) {
      debugPrint('DBA_DEBUG: CRITICAL ERROR in fetchDrivers: $e');
      return [];
    }
  }

  // Legacy alias
  static Future<List<Driver>> getDrivers() => fetchDrivers();

  static Future<void> upsertDriver(Driver driver) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = driver.toJson();
    data['owner_id'] = userId;

    await _supabase.from('drivers').upsert(data);
  }

  static Future<void> deleteDriver(String driverId) async {
    await _supabase.from('drivers').delete().eq('id', driverId);
  }

  // Legacy helpers for import dialogs
  static Future<String?> getDriverIdFromAlias(String alias) async => null;
  static Future<void> saveDriverAlias(String alias, String driverId) async {}

  static Future<Driver?> getDriverById(String id) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('DBA_DEBUG: getDriverById error: $e');
      return null;
    }
  }

  static Future<Driver?> getDriverByName(String name) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('owner_id', userId)
          .ilike('name', name.trim())
          .maybeSingle();
      if (response == null) return null;
      return Driver.fromJson(response);
    } catch (e) {
      debugPrint('DBA_DEBUG: getDriverByName error: $e');
      return null;
    }
  }

  // ==========================================
  // ২. এপিআই ক্রেডেনশিয়াল (API Credentials)
  // ==========================================

  static Future<void> saveCredentials({
    required String clientId,
    required String clientSecret,
    String? fleetId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('platform_credentials').upsert({
      'owner_id': userId,
      'platform_name': 'bolt',
      'client_id': clientId,
      'client_secret': clientSecret,
      'fleet_id': fleetId,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'owner_id,platform_name');
  }

  static Future<Map<String, dynamic>?> fetchCredentials() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('platform_credentials')
        .select()
        .eq('owner_id', userId)
        .eq('platform_name', 'bolt')
        .maybeSingle();
    
    return response;
  }

  // ==========================================
  // ৩. সেটিংস (Settings)
  // ==========================================

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('profiles').update(settings).eq('id', userId);
  }

  static Future<Map<String, dynamic>?> getSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    return await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
  }

  // ==========================================
  // ৪. ট্রানজ্যাকশন এবং ইম্পোর্ট (Unified earnings_raw)
  // ==========================================

  /// Fetch all earnings for the current user from the unified table
  static Future<List<dynamic>> getEarnings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('DBA_DEBUG: getEarnings — user not authenticated');
      return [];
    }
    try {
      final response = await _supabase
          .from('earnings_raw')
          .select()
          .eq('owner_id', userId)
          .order('date', ascending: false);
      debugPrint('DBA_DEBUG: getEarnings — fetched ${(response as List).length} rows');
      return response;
    } catch (e) {
      debugPrint('DBA_DEBUG: getEarnings error: $e');
      return [];
    }
  }

  /// Save a single earnings entry (manual add) to earnings_raw
  static Future<void> saveEarnings(dynamic entry) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Support both EarningsEntry objects (via toMap) and plain maps
    final Map<String, dynamic> data;
    if (entry is Map<String, dynamic>) {
      data = entry;
    } else {
      data = (entry as dynamic).toMap() as Map<String, dynamic>;
    }

    // Build normalized earnings_raw row
    final row = <String, dynamic>{
      'id': data['id'] ?? 'manual_${DateTime.now().millisecondsSinceEpoch}',
      'owner_id': userId,
      'driver_id': data['driverId'] ?? data['driver_id'],
      'brutto_amount': data['bruttoAmount'] ?? data['brutto_amount'] ?? 0,
      'net_amount': data['nettoAmount'] ?? data['net_amount'] ?? 0,
      'moms_amount': data['moms6'] ?? data['moms_amount'] ?? 0,
      'platform_fee': data['platformFee'] ?? data['platform_fee'] ?? 0,
      'dricks': data['dricks'] ?? 0,
      'platform': data['platformId'] ?? data['platform'] ?? 'manual',
      'source': data['source'] ?? 'manual',
      'week_number': data['weekNumber'] ?? data['week_number'],
      'entry_month': data['month'],
      'entry_year': data['year'],
      'reference': data['reference'],
    };

    // Derive date from entry_month/entry_year if not provided
    if (row['date'] == null && row['entry_month'] != null && row['entry_year'] != null) {
      row['date'] = '${row['entry_year']}-${row['entry_month'].toString().padLeft(2, '0')}-01';
    }

    debugPrint('DBA_DEBUG: saveEarnings → upserting id: ${row['id']}');
    await _supabase.from('earnings_raw').upsert(row, onConflict: 'id');
  }

  /// Save a batch of earnings entries (CSV/Excel import) to earnings_raw
  static Future<void> saveEarningsBatch(List<dynamic> batch) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    if (batch.isEmpty) return;

    final List<Map<String, dynamic>> rows = batch.map((entry) {
      final Map<String, dynamic> data;
      if (entry is Map<String, dynamic>) {
        data = entry;
      } else {
        data = (entry as dynamic).toMap() as Map<String, dynamic>;
      }

      final row = <String, dynamic>{
        'id': data['id'] ?? 'csv_${DateTime.now().millisecondsSinceEpoch}_${batch.indexOf(entry)}',
        'owner_id': userId,
        'driver_id': data['driverId'] ?? data['driver_id'],
        'brutto_amount': data['bruttoAmount'] ?? data['brutto_amount'] ?? 0,
        'net_amount': data['nettoAmount'] ?? data['net_amount'] ?? 0,
        'moms_amount': data['moms6'] ?? data['moms_amount'] ?? 0,
        'platform_fee': data['platformFee'] ?? data['platform_fee'] ?? 0,
        'dricks': data['dricks'] ?? 0,
        'platform': data['platformId'] ?? data['platform'] ?? 'bolt',
        'source': 'csv',
        'week_number': data['weekNumber'] ?? data['week_number'],
        'entry_month': data['month'],
        'entry_year': data['year'],
        'reference': data['reference'],
      };

      if (row['date'] == null && row['entry_month'] != null && row['entry_year'] != null) {
        row['date'] = '${row['entry_year']}-${row['entry_month'].toString().padLeft(2, '0')}-01';
      }

      return row;
    }).toList();

    debugPrint('DBA_DEBUG: saveEarningsBatch → upserting ${rows.length} rows to earnings_raw');
    // Upsert in chunks of 50 to avoid request size limits
    for (int i = 0; i < rows.length; i += 50) {
      final chunk = rows.sublist(i, i + 50 > rows.length ? rows.length : i + 50);
      await _supabase.from('earnings_raw').upsert(chunk, onConflict: 'id');
    }
    debugPrint('DBA_DEBUG: saveEarningsBatch → done');
  }

  /// Save an import history record
  static Future<void> saveImportHistory(dynamic history) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final Map<String, dynamic> data;
      if (history is Map<String, dynamic>) {
        data = history;
      } else {
        data = {
          'id': (history as dynamic).id,
          'file_name': history.fileName,
          'import_date': history.importDate.toIso8601String(),
          'platform_id': history.platformId,
          'total_rows': history.totalRowsProcessed,
          'total_brutto': history.totalBruttoCalculated,
        };
      }
      await _supabase.from('import_history').upsert({
        ...data,
        'owner_id': userId,
      });
    } catch (e) {
      // Non-critical — log and continue
      debugPrint('DBA_DEBUG: saveImportHistory error (non-critical): $e');
    }
  }

  static Future<void> saveMappingPreset(dynamic preset) async {}

  // ==========================================
  // ৫. সেটেলমেন্ট (Settlements)
  // ==========================================

  static Future<void> saveSettlement(MonthlyPayroll payroll) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('settlements').insert({
      'owner_id': userId,
      'driver_id': payroll.driverId,
      'period_month': payroll.month,
      'period_year': payroll.year,
      'brutto': payroll.totalBrutto,
      'net_revenue': payroll.totalNetto,
      'moms': payroll.totalMoms, // Changed from momsAmount to totalMoms for safety
      'soc_fees': payroll.arbetsgivaravgifter,
      'tax': payroll.preliminaryTax,
      'payout': payroll.takeHomePay,
      'profit': payroll.netProfit,
    });

    await _supabase
        .from('earnings_raw')
        .update({'is_settled': true})
        .eq('owner_id', userId)
        .eq('driver_id', payroll.driverId)
        .eq('is_settled', false);
  }

  static Future<List<dynamic>> fetchSettlements(int month, int year) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('settlements')
        .select('*, drivers(name)')
        .eq('owner_id', userId)
        .eq('period_month', month)
        .eq('period_year', year);

    return response;
  }
}
