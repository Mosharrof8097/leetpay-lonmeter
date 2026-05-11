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

  bool get isValid => driverNameIdx != -1 && bruttoIdx != -1 && (weekIdx != -1 || dateIdx != -1);

  Map<String, int> toMap() => {
    'driverNameIdx': driverNameIdx,
    'bruttoIdx': bruttoIdx,
    'nettoIdx': nettoIdx,
    'weekIdx': weekIdx,
    'dricksIdx': dricksIdx,
    'dateIdx': dateIdx,
    'feeIdx': feeIdx,
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
        if (excel.tables.isEmpty) return null;
        final table = excel.tables.values.first;
        if (table.rows.isEmpty) return null;
        return table.rows.first.map((c) => c?.value?.toString() ?? '').toList();
      } else if (filePath.endsWith('.csv')) {
        final input = File(filePath).openRead();
        final fields = await input
            .transform(utf8.decoder)
            .handleError((_) => utf8.decode([0xEF, 0xBB, 0xBF])) // Handle potential BOM
            .transform(const CsvDecoder())
            .first;
        return fields.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error getting headers: $e');
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
      final rawBrutto = getVal(mapping.bruttoIdx).replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      final rawNetto = getVal(mapping.nettoIdx).replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      final rawDricks = getVal(mapping.dricksIdx).replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      final rawFee = getVal(mapping.feeIdx).replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      
      if (rawName.isEmpty) continue;

      // 1. Resolve Name - Check Supabase
      String? driverId;
      double appliedRate = 0.43;
      final existingDriver = await SupabaseService.getDriverByName(rawName);
      
      if (existingDriver != null) {
        driverId = existingDriver.id;
        appliedRate = existingDriver.commissionRate;
      } else {
        // AUTO-CREATE Driver
        final newId = _uuid.v4();
        appliedRate = DatabaseService.getDefaultCommissionRate();
        await SupabaseService.upsertDriver(Driver(
          id: newId,
          name: rawName,
          commissionRate: appliedRate,
        ));
        driverId = newId;
        debugPrint('Auto-created driver: $rawName ($newId)');
      }

      if (driverId == null) continue;

      final brutto = double.tryParse(rawBrutto) ?? 0.0;
      final csvNetto = double.tryParse(rawNetto) ?? 0.0;
      final dricks = double.tryParse(rawDricks) ?? 0.0;
      final platformFee = (double.tryParse(rawFee) ?? 0.0).abs(); // Handle negative values if any
      
      int week = 0;
      int entryMonth = now.month;
      int entryYear = now.year;
      
      if (mapping.dateIdx != -1) {
        final dateStr = getVal(mapping.dateIdx);
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          week = _getIsoWeekNumber(date);
          entryMonth = date.month;
          entryYear = date.year;
        }
      } 
      
      if (week == 0 && mapping.weekIdx != -1) {
        week = int.tryParse(getVal(mapping.weekIdx)) ?? 0;
      }

      if (brutto == 0) continue;

      // Calculate Netto (Inkomst)
      // If the CSV has a Netto column (which usually has platform fees deducted), use it.
      // Otherwise, we calculate it from Brutto.
      // NOTE: In both cases, we must divide by 1.06 to get the amount before Swedish VAT.
      double netto;
      if (mapping.nettoIdx != -1 && csvNetto > 0) {
        netto = csvNetto / (1 + kMoms6);
      } else {
        // Correct Dynamic Logic: Netto = (Brutto - Actual Fee) / 1.06
        final actualGross = brutto - platformFee;
        netto = actualGross / (1 + kMoms6);
      }
      
      final moms = (brutto) - (brutto / (1 + kMoms6)); // Total Moms from Gross

      final entry = EarningsEntry(
        id: _uuid.v4(), 
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
      );

      await SupabaseService.saveEarnings(entry);
      totalBrutto += brutto;
      importedCount++;
    }

    if (importedCount > 0) {
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
    return table.rows.map((r) => r.map((c) => c?.value).toList()).toList();
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
}

