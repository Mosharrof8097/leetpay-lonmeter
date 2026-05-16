import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/earnings_entry.dart';
import '../models/driver.dart';
import '../models/import_history.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import '../services/calculation_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../utils/swedish_tax_constants.dart';

class ColumnMapping {
  int driverNameIdx = -1;
  int bruttoIdx = -1;
  int nettoIdx = -1;
  int weekIdx = -1;
  int dricksIdx = -1;
  int dateIdx = -1;
  int feeIdx = -1;
  int referenceIdx = -1;

  bool get isValid => driverNameIdx != -1 && bruttoIdx != -1 && (weekIdx != -1 || dateIdx != -1);

  Map<String, int> toMap() => {
    'driverNameIdx': driverNameIdx,
    'bruttoIdx': bruttoIdx,
    'nettoIdx': nettoIdx,
    'weekIdx': weekIdx,
    'dricksIdx': dricksIdx,
    'dateIdx': dateIdx,
    'feeIdx': feeIdx,
    'referenceIdx': referenceIdx,
  };

  static ColumnMapping fromMap(Map<dynamic, dynamic> map) {
    final m = ColumnMapping();
    m.driverNameIdx = map['driverNameIdx'] ?? -1;
    m.bruttoIdx = map['bruttoIdx'] ?? -1;
    m.nettoIdx = map['nettoIdx'] ?? -1;
    m.weekIdx = map['weekIdx'] ?? -1;
    m.dricksIdx = map['dricksIdx'] ?? -1;
    m.dateIdx = map['dateIdx'] ?? -1;
    m.feeIdx = map['feeIdx'] ?? -1;
    m.referenceIdx = map['referenceIdx'] ?? -1;
    return m;
  }
}

class FileImportService {
  static const _uuid = Uuid();

  static Future<List<String>?> getHeaders(String filePath) async {
    try {
      if (filePath.endsWith('.xlsx')) {
        final bytes = await File(filePath).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        
        if (excel.tables.isEmpty) {
          debugPrint('Excel file has no visible sheets.');
          return null;
        }
        
        final table = excel.tables.values.first;
        if (table.rows.isEmpty) return null;
        
        final firstRow = table.rows.first;
        return firstRow.map((c) => c?.value?.toString() ?? '').toList();
      } else if (filePath.endsWith('.csv')) {
        final input = File(filePath).openRead();
        final fields = await input
            .transform(utf8.decoder)
            .handleError((_) => utf8.decode([0xEF, 0xBB, 0xBF]))
            .transform(const CsvDecoder())
            .first;
        return fields.map((e) => e?.toString() ?? '').toList();
      }
    } catch (e, stack) {
      if (e is TypeError || e.toString().contains('Null check operator')) {
        debugPrint('Excel Decoding Error: The file format is too complex or incompatible.');
        throw Exception('This Excel file format is not supported. Please save it as a CSV file and try again.');
      }
      debugPrint('Error getting headers: $e');
      debugPrint('Stack trace: $stack');
    }
    return null;
  }

  static Future<int> processImport({
    required String filePath,
    required String platformId,
    required ColumnMapping mapping,
    required Future<String?> Function(String unmatchedName) onNameMismatch,
  }) async {
    final data = await _readAllRows(filePath);
    if (data == null || data.length < 2) return 0;

    int importedCount = 0;
    double totalBrutto = 0;
    final List<EarningsEntry> entries = [];
    final importId = _uuid.v4();
    final now = DateTime.now();

    for (var i = 1; i < data.length; i++) {
      final row = data[i];
      if (row.isEmpty) continue;

      String getVal(int idx) {
        if (idx == -1 || idx >= row.length) return '';
        final v = row[idx];
        return v?.toString().trim() ?? '';
      }

      final rawName = getVal(mapping.driverNameIdx);
      final rawBrutto = _cleanNumericString(getVal(mapping.bruttoIdx));
      final rawNetto = _cleanNumericString(getVal(mapping.nettoIdx));
      final rawDricks = _cleanNumericString(getVal(mapping.dricksIdx));
      final rawFee = _cleanNumericString(getVal(mapping.feeIdx));
      final reference = getVal(mapping.referenceIdx);
      
      if (rawName.isEmpty) {
        debugPrint('Skipping row $i: Missing driver name');
        continue;
      }

      // 1. Resolve Name - Check Alias first, then Supabase
      String? driverId;
      double appliedRate = DatabaseService.getDefaultCommissionRate();
      
      // Check Alias Resolver first (Try Supabase then local Hive backup)
      String? aliasedDriverId = await SupabaseService.getDriverIdFromAlias(rawName);
      aliasedDriverId ??= DatabaseService.getDriverIdFromAlias(rawName);
      
      if (aliasedDriverId != null) {
        final driver = await SupabaseService.getDriverById(aliasedDriverId);
        if (driver != null) {
          driverId = driver.id;
          appliedRate = driver.commissionRate;
        }
      }

      if (driverId == null) {
        final existingDriver = await SupabaseService.getDriverByName(rawName);
        if (existingDriver != null) {
          driverId = existingDriver.id;
          appliedRate = existingDriver.commissionRate;
        } else {
          // INTERACTIVE Alias Resolver or Auto-create
          final resolvedId = await onNameMismatch(rawName);
          if (resolvedId != null) {
            driverId = resolvedId;
            final d = await SupabaseService.getDriverById(driverId);
            appliedRate = d?.commissionRate ?? appliedRate;
          } else {
            // Last resort: skip if not resolved
            continue;
          }
        }
      }

      if (driverId == null) {
        debugPrint('Skipping row $i: Could not resolve driver $rawName');
        continue;
      }

      final brutto = double.tryParse(rawBrutto) ?? 0.0;
      final csvNetto = double.tryParse(rawNetto) ?? 0.0;
      final dricks = double.tryParse(rawDricks) ?? 0.0;
      final platformFee = (double.tryParse(rawFee) ?? 0.0).abs(); // Handle negative values if any
      
      int week = 0;
      int entryMonth = now.month;
      int entryYear = now.year;
      
      if (mapping.dateIdx != -1) {
        final dateStr = getVal(mapping.dateIdx);
        final date = _parseDate(dateStr);
        if (date != null) {
          week = _getIsoWeekNumber(date);
          entryMonth = date.month;
          entryYear = date.year;
        }
      } 
      
      if (week == 0 && mapping.weekIdx != -1) {
        week = int.tryParse(getVal(mapping.weekIdx)) ?? 0;
      }

      if (brutto == 0) {
        debugPrint('Skipping row $i: Zero earnings');
        continue;
      }

      // Calculate Netto (Inkomst)
      // If the CSV has a Netto column (which usually has platform fees deducted), use it.
      // Otherwise, we calculate it from Brutto.
      double netto;
      if (mapping.nettoIdx != -1 && csvNetto > 0) {
        netto = csvNetto / (1 + kMoms6);
      } else {
        final actualGross = brutto - platformFee;
        netto = actualGross / (1 + kMoms6);
      }
      
      final moms = (brutto) - (brutto / (1 + kMoms6));

      // 2. Generate Deterministic ID (Duplicate Protection)
      final deterministicId = reference.isNotEmpty 
          ? '${platformId}_${reference.replaceAll(RegExp(r'\s+'), '')}'
          : _uuid.v5(Uuid.NAMESPACE_URL, '$platformId-$driverId-$entryYear-$entryMonth-$week-$brutto');

      final entry = EarningsEntry(
        id: deterministicId, 
        driverId: driverId,
        weekNumber: week,
        month: entryMonth,
        year: entryYear,
        platformId: platformId,
        bruttoAmount: brutto,
        nettoAmount: netto,
        moms6: moms,
        dricks: dricks,
        appliedPercentage: appliedRate,
        platformFee: platformFee,
        reference: reference,
      );

      entries.add(entry);
      totalBrutto += brutto;
      importedCount++;
    }

    if (entries.isNotEmpty) {
      await SupabaseService.saveEarningsBatch(entries);
      
      await SupabaseService.saveImportHistory(ImportHistoryModel(
        id: importId,
        fileName: filePath.split('/').last,
        importDate: now,
        platformId: platformId,
        totalRowsProcessed: importedCount,
        totalBruttoCalculated: totalBrutto,
      ));
    }

    return importedCount;
  }

  static Future<List<List<dynamic>>?> _readAllRows(String filePath) async {
    try {
      final file = File(filePath);
      if (!(await file.exists())) return null;

      if (filePath.endsWith('.xlsx')) {
        final bytes = await file.readAsBytes();
        return await compute(_parseExcel, bytes);
      } else if (filePath.endsWith('.csv')) {
        final content = await file.readAsString();
        return await compute(_parseCsv, content);
      }
    } catch (e) {
      debugPrint('Error reading rows: $e');
    }
    return null;
  }

  static List<List<dynamic>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final table = excel.tables.values.first;
    
    return table.rows.map((r) {
      // Ensure r is not null before mapping
      return r.map((c) => c?.value).toList();
    }).toList();
  }

  static List<List<dynamic>> _parseCsv(String content) {
    return const CsvDecoder().convert(content);
  }

  static int _getIsoWeekNumber(DateTime date) {
    // ISO week date weeks start on Monday.
    // The first week of the year is the week that contains the first Thursday of the year.
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return _getIsoWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (woy > 52) {
      final nextYearJan4 = DateTime(date.year + 1, 1, 4);
      if (woy > 52 && date.isAfter(nextYearJan4.subtract(Duration(days: nextYearJan4.weekday - 1)))) {
        return 1;
      }
    }
    return woy;
  }

  static int findBestColumnMatch(List<String> headers, List<String> keywords) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      for (final keyword in keywords) {
        if (header == keyword.toLowerCase() || header.contains(keyword.toLowerCase())) return i;
      }
    }
    return -1;
  }

  static String _cleanNumericString(String value) {
    if (value.isEmpty) return '0.0';
    
    String cleaned = value.trim();
    // Handle trailing minus (e.g. "100.00-")
    if (cleaned.endsWith('-')) {
      cleaned = '-' + cleaned.substring(0, cleaned.length - 1);
    }
    
    // Remove everything except numbers, dots, commas, and negative signs
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9.,-]'), '');
    // Replace comma with dot for decimal separation
    cleaned = cleaned.replaceAll(',', '.');
    // Ensure only the last dot is kept if there are multiple (thousands separators)
    if (cleaned.split('.').length > 2) {
      int lastDotIndex = cleaned.lastIndexOf('.');
      cleaned = cleaned.substring(0, lastDotIndex).replaceAll('.', '') + cleaned.substring(lastDotIndex);
    }
    return cleaned;
  }

  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    // Try standard DateTime.tryParse
    DateTime? parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed.toUtc();

    // Try common formats
    final formats = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'dd.MM.yyyy',
      'yyyy/MM/dd',
      'MMM dd, yyyy',
      'dd MMM yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr).toUtc();
      } catch (_) {}
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getPreviewData(String filePath, ColumnMapping mapping) async {
    final data = await _readAllRows(filePath);
    if (data == null || data.length < 2) return [];

    List<Map<String, dynamic>> preview = [];
    int rowCount = data.length > 6 ? 6 : data.length;

    for (int i = 1; i < rowCount; i++) {
      final row = data[i];
      String getVal(int idx) {
        if (idx == -1 || idx >= row.length) return '';
        return row[idx]?.toString().trim() ?? '';
      }

      final rawName = getVal(mapping.driverNameIdx);
      final rawBrutto = _cleanNumericString(getVal(mapping.bruttoIdx));
      final dateStr = mapping.dateIdx != -1 ? getVal(mapping.dateIdx) : '';
      
      final brutto = double.tryParse(rawBrutto) ?? 0.0;
      final date = _parseDate(dateStr);

      bool isValid = rawName.isNotEmpty && brutto > 0 && (date != null || mapping.weekIdx != -1);

      preview.add({
        'row': i,
        'driver': rawName,
        'brutto': brutto,
        'date': date?.toIso8601String() ?? dateStr,
        'isValid': isValid,
        'originalRow': row,
      });
    }
    return preview;
  }
}

