import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/driver.dart';
import '../models/earnings_entry.dart';
import '../models/import_history.dart';
import '../models/driver_alias.dart';
import '../services/database_service.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || anonKey == null) {
        throw Exception('Supabase credentials missing in .env file');
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
      rethrow;
    }
  }

  // --- Drivers ---
  static Future<List<Driver>> getDrivers() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await client.from('drivers').select().eq('user_id', userId).order('name');
    if (response == null) return [];
    
    return (response as List).map((d) => Driver(
      id: d['id'],
      name: d['name'] ?? 'Unknown',
      commissionRate: (d['commission_rate'] as num?)?.toDouble() ?? 0.43,
      isActive: d['is_active'] ?? true,
    )).toList();
  }

  static Future<Driver?> getDriverByName(String name) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await client.from('drivers')
        .select()
        .eq('user_id', userId)
        .ilike('name', name)
        .maybeSingle();
    
    if (response == null) return null;
    return Driver(
      id: response['id'],
      name: response['name'],
      commissionRate: (response['commission_rate'] as num).toDouble(),
      isActive: response['is_active'],
    );
  }

  static Future<void> upsertDriver(Driver driver) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('drivers').upsert({
      'id': driver.id,
      'user_id': userId,
      'name': driver.name,
      'commission_rate': driver.commissionRate,
      'is_active': driver.isActive,
    });
  }

  static Future<void> deleteDriver(String id) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('drivers').delete().eq('id', id).eq('user_id', userId);
  }

  // --- Earnings ---
  static Future<List<EarningsEntry>> getEarnings() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await client.from('earnings').select().eq('user_id', userId).order('created_at', ascending: false);
    if (response == null) return [];
    
    return (response as List).map((e) => EarningsEntry(
      id: e['id'],
      driverId: e['driver_id'] ?? '',
      weekNumber: e['week_number'] ?? 0,
      month: e['month'] ?? 1,
      year: e['year'] ?? 2024,
      platformId: e['platform_id'] ?? 'uber',
      bruttoAmount: (e['brutto'] as num?)?.toDouble() ?? 0.0,
      nettoAmount: (e['netto'] as num?)?.toDouble() ?? 0.0,
      moms6: (e['moms'] as num?)?.toDouble() ?? 0.0,
      socialFees: (e['social_fees'] as num?)?.toDouble() ?? 0.0,
      dricks: (e['dricks'] as num?)?.toDouble() ?? 0.0,
      appliedPercentage: (e['applied_percentage'] as num?)?.toDouble(),
      platformFee: (e['platform_fee'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }

  static Future<void> saveEarnings(EarningsEntry entry) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client.from('earnings').upsert({
        'id': entry.id,
        'user_id': userId,
        'driver_id': entry.driverId,
        'platform_id': entry.platformId,
        'week_number': entry.weekNumber,
        'month': entry.month,
        'year': entry.year,
        'brutto': entry.bruttoAmount,
        'netto': entry.nettoAmount,
        'moms': entry.moms6,
        'social_fees': entry.socialFees,
        'dricks': entry.dricks,
        'applied_percentage': entry.appliedPercentage,
        'platform_fee': entry.platformFee,
      });
    } catch (e) {
      debugPrint('Error saving earnings to Supabase: $e');
      rethrow; // Rethrow so the provider can handle UI feedback
    }
  }

  static Future<void> saveImportHistory(ImportHistoryModel history) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('import_history').upsert({
      'id': history.id,
      'user_id': userId,
      'file_name': history.fileName,
      'created_at': history.importDate.toIso8601String(),
      'platform_id': history.platformId,
      'total_rows': history.totalRowsProcessed,
      'total_brutto': history.totalBruttoCalculated,
    });
  }

  // --- Settings ---
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return {};
      final response = await client.from('settings').select().eq('user_id', userId).maybeSingle();
      return response ?? {
        'company_name': 'Lönmeter AB',
        'commission_rates': [0.37, 0.43, 0.45],
        'default_commission_rate': 0.43,
      };
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      return {
        'company_name': 'Lönmeter AB',
        'commission_rates': [0.37, 0.43, 0.45],
        'default_commission_rate': 0.43,
      };
    }
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    
    // Ensure user_id is included for upsert
    final data = {
      ...settings,
      'user_id': userId,
    };
    
    await client.from('settings').upsert(data);
  }

  // --- Migration Logic ---
  static Future<void> migrateFromHive() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final drivers = DatabaseService.getAllDrivers();
    final earnings = DatabaseService.getAllEarnings();

    if (drivers.isEmpty && earnings.isEmpty) return;

    // Migrate Drivers
    for (var d in drivers) {
      await upsertDriver(d);
    }

    // Migrate Earnings
    for (var e in earnings) {
      await saveEarnings(e);
    }

    // Clear Hive after successful migration
    await DatabaseService.clearAllData();
  }
}
