
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ImportService {
  static final _supabase = Supabase.instance.client;

  /// Main entry point to pick a file and import its data
  static Future<Map<String, dynamic>> pickAndImport(String platform) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result == null || result.files.isEmpty) {
      return {'success': false, 'message': 'No file selected'};
    }

    final file = File(result.files.first.path!);
    final extension = result.files.first.extension?.toLowerCase();

    List<List<dynamic>> rows = [];

    try {
      if (extension == 'csv') {
        rows = await _parseCSVManual(file);
      } else {
        rows = await _parseExcel(file);
      }

      if (rows.isEmpty) throw Exception('The file appears to be empty');

      return await _processRows(rows, platform);
    } catch (e) {
      return {'success': false, 'message': 'Import failed: $e'};
    }
  }

  /// Manual CSV Parser to avoid problematic 'csv' package issues
  static Future<List<List<dynamic>>> _parseCSVManual(File file) async {
    final List<List<dynamic>> rows = [];
    final lines = await file.readAsLines();
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Simple comma/semicolon splitter
      // Most European CSVs (Sweden) use semicolon ; while international use comma ,
      final separator = line.contains(';') ? ';' : ',';
      final parts = line.split(separator).map((p) {
        // Remove quotes if present
        var clean = p.trim();
        if (clean.startsWith('"') && clean.endsWith('"')) {
          clean = clean.substring(1, clean.length - 1);
        }
        return clean;
      }).toList();
      
      rows.add(parts);
    }
    return rows;
  }

  static Future<List<List<dynamic>>> _parseExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<List<dynamic>> rows = [];

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        rows.add(row.map((cell) => cell?.value).toList());
      }
      break; // Only process the first sheet
    }
    return rows;
  }

  static Future<Map<String, dynamic>> _processRows(List<List<dynamic>> rows, String platform) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // 1. Identify Headers (Smart Mapping)
    final headers = rows.first.map((h) => h.toString().toLowerCase().trim()).toList();
    
    // Smart column mapping — supports both our template and Bolt/Uber native exports
    int nameIdx = _findColumn(headers, ['driver_name', 'driver', 'förare', 'name', 'förarnamn', 'chauffeur']);
    int bruttoIdx = _findColumn(headers, ['gross_amount', 'brutto_amount', 'brutto', 'gross', 'amount', 'total', 'pris total', 'ride_price', 'total_price']);
    int nettoIdx = _findColumn(headers, ['net_amount', 'netto_amount', 'netto', 'net', 'earnings', 'driver earnings', 'net_earnings']);
    int dateIdx = _findColumn(headers, ['date', 'datum', 'timestamp', 'created', 'order_date', 'trip_date']);
    int tipsIdx = _findColumn(headers, ['tips', 'dricks', 'tip', 'tip_amount', 'gratuity']);
    int platformIdx = _findColumn(headers, ['platform', 'service', 'app']);

    if (nameIdx == -1 || bruttoIdx == -1) {
      throw Exception(
        'Mandatory columns missing!\n\n'
        'File has: ${headers.join(", ")}\n\n'
        'Required: a driver name column AND a gross amount column.\n'
        'Use the standard template for guaranteed compatibility.'
      );
    }

    // 2. Fetch current drivers for matching
    final drivers = await SupabaseService.fetchDrivers();
    final Map<String, String> driverCache = {for (var d in drivers) d.name.toLowerCase().trim(): d.id};
    int importedCount = 0;

    // 3. Process Data Rows
    final List<Map<String, dynamic>> dataToInsert = [];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= nameIdx || row[nameIdx] == null) continue;

      final String rawName = row[nameIdx].toString().trim();
      if (rawName.isEmpty) continue;
      
      final double brutto = _parseDouble(row[bruttoIdx]);
      if (brutto == 0) continue;

      final nameKey = rawName.toLowerCase().trim();
      String? matchedDriverId = driverCache[nameKey];

      // Auto-create driver if doesn't exist
      if (matchedDriverId == null) {
        try {
          try {
            // First attempt: include bolt_uuid (if column exists)
            final newDriver = await _supabase.from('drivers').insert({
              'owner_id': userId,
              'name': rawName,
            }).select().single();
            matchedDriverId = newDriver['id'];
          } catch (e) {
            // Ultimate fallback
            final newDriver = await _supabase.from('drivers').insert({
              'owner_id': userId,
              'name': rawName,
            }).select().single();
            matchedDriverId = newDriver['id'];
          }
          
          driverCache[nameKey] = matchedDriverId!;
          debugPrint('ImportService: Auto-created new driver: $rawName');
        } catch (e) {
          debugPrint('ImportService: Error auto-creating driver: $e');
          continue; 
        }
      }

      final double netto = nettoIdx != -1 ? _parseDouble(row[nettoIdx]) : brutto * 0.8;
      final double tips = tipsIdx != -1 ? _parseDouble(row[tipsIdx]) : 0.0;
      final double moms = brutto * 0.0566;
      final String date = dateIdx != -1 ? _parseDate(row[dateIdx]) : DateTime.now().toIso8601String().split('T')[0];
      
      // Detect platform from column or use the selected one
      String detectedPlatform = platform.toLowerCase();
      if (platformIdx != -1 && row.length > platformIdx && row[platformIdx] != null) {
        detectedPlatform = row[platformIdx].toString().toLowerCase().trim();
      }

      // Parse month and year from date
      DateTime parsedDate;
      try {
        parsedDate = DateTime.parse(date);
      } catch (_) {
        parsedDate = DateTime.now();
      }

      // Deterministic ID: prevents duplicate imports
      final deterministicId = 'csv_${detectedPlatform}_${matchedDriverId}_${date}_${brutto.toStringAsFixed(0)}';

      dataToInsert.add({
        'id': deterministicId,
        'owner_id': userId,
        'driver_id': matchedDriverId,
        'driver_name': rawName,
        'brutto_amount': brutto,
        'net_amount': netto,
        'moms_amount': moms,
        'platform_fee': brutto - netto,
        'dricks': tips,
        'platform': detectedPlatform,
        'source': 'csv_import',
        'date': date,
        'entry_month': parsedDate.month,
        'entry_year': parsedDate.year,
      });
      importedCount++;
    }

    if (dataToInsert.isNotEmpty) {
      // Upsert: safe to import same file multiple times (no duplicates)
      await _supabase.from('earnings_raw').upsert(dataToInsert, onConflict: 'id');
      debugPrint('ImportService: ✅ Upserted $importedCount rows to earnings_raw');
    }

    return {
      'success': true, 
      'message': 'Successfully imported $importedCount records for $platform',
      'count': importedCount,
    };
  }

  static int _findColumn(List<String> headers, List<String> keywords) {
    for (var keyword in keywords) {
      final idx = headers.indexWhere((h) => h.contains(keyword));
      if (idx != -1) return idx;
    }
    return -1;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  static String _parseDate(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String().split('T')[0];
    try {
      final date = DateTime.parse(value.toString());
      return date.toIso8601String().split('T')[0];
    } catch (_) {
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }
}
