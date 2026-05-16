import 'package:hive_flutter/hive_flutter.dart';
import '../models/driver.dart';
import '../models/earnings_entry.dart';
import '../models/import_history.dart';
import '../models/driver_alias.dart';
import '../models/mapping_preset.dart';

class DatabaseService {
  static const String _driversBox = 'drivers';
  static const String _earningsBox = 'earnings';
  static const String _settingsBox = 'settings';
  static const String _platformsBox = 'platforms';
  static const String _historyBox = 'import_history';
  static const String _aliasBox = 'driver_aliases';
  static const String _presetBox = 'mapping_presets';
  
  static late Box<Driver> _driverBox;
  static late Box<EarningsEntry> _earningBox;
  static late Box<ImportHistoryModel> _importHistoryBox;
  static late Box<DriverAliasModel> _driverAliasBox;
  static late Box<MappingPreset> _mappingPresetBox;
  static late Box<dynamic> _settingBox;


  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DriverAdapter());

    Hive.registerAdapter(EarningsEntryAdapter());
    Hive.registerAdapter(ImportHistoryModelAdapter());
    Hive.registerAdapter(DriverAliasModelAdapter());
    Hive.registerAdapter(MappingPresetAdapter());

    _driverBox = await Hive.openBox<Driver>(_driversBox);
    _earningBox = await Hive.openBox<EarningsEntry>(_earningsBox);
    _importHistoryBox = await Hive.openBox<ImportHistoryModel>(_historyBox);
    _driverAliasBox = await Hive.openBox<DriverAliasModel>(_aliasBox);
    _mappingPresetBox = await Hive.openBox<MappingPreset>(_presetBox);
    _settingBox = await Hive.openBox<dynamic>(_settingsBox);


    await _initDefaults();
  }

  static Future<void> _initDefaults() async {
    // Basic defaults
  }


  static List<Driver> getAllDrivers() => _driverBox.values.toList();
  static List<Driver> getActiveDrivers() => _driverBox.values.where((d) => d.isActive).toList();
  static Driver? getDriver(String id) {
    try { return _driverBox.values.firstWhere((d) => d.id == id); } catch (_) { return null; }
  }
  static Future<void> addDriver(Driver driver) => _driverBox.put(driver.id, driver);
  static Future<void> updateDriver(Driver driver) => _driverBox.put(driver.id, driver);
  static Future<void> deleteDriver(String id) => _driverBox.delete(id);

  static List<EarningsEntry> getAllEarnings() => _earningBox.values.toList();
  static List<EarningsEntry> getEarningsForDriver(String driverId) => _earningBox.values.where((e) => e.driverId == driverId).toList();
  static List<EarningsEntry> getEarningsForMonth(int month, int year) => _earningBox.values.where((e) => e.month == month && e.year == year).toList();
  static Future<void> saveEarnings(EarningsEntry entry) => _earningBox.put(entry.id, entry);
  static Future<void> deleteEarnings(String id) => _earningBox.delete(id);

  static String getCompanyName() => _settingBox.get('companyName', defaultValue: 'Min Vagnpark') as String;
  static double getDefaultCommissionRate() => 0.43;

  static int getTaxYear() => _settingBox.get('taxYear', defaultValue: DateTime.now().year) as int;
  static dynamic getSetting(String key, {dynamic defaultValue}) => _settingBox.get(key, defaultValue: defaultValue);
  static Future<void> saveSetting(String key, dynamic value) => _settingBox.put(key, value);

  static Future<Map<String, dynamic>> exportBackup() async {
    return exportAllData();
  }

  static Map<String, dynamic> exportAllData() => {
    'drivers': getAllDrivers().map((d) => d.toMap()).toList(),
    'earnings': getAllEarnings().map((e) => e.toMap()).toList(),
    'settings': {
      'companyName': getCompanyName(),
      'taxYear': getTaxYear(),
    },

    'exportDate': DateTime.now().toIso8601String(),
    'version': 1,
  };

  static Future<void> importAllData(Map<String, dynamic> data) async {
    await _driverBox.clear();
    await _earningBox.clear();
    if (data['drivers'] != null) {
      for (var d in data['drivers']) {
        final driver = Driver.fromMap(Map<String, dynamic>.from(d));
        await _driverBox.put(driver.id, driver);
      }
    }
    if (data['earnings'] != null) {
      for (var e in data['earnings']) {
        final entry = EarningsEntry.fromMap(Map<String, dynamic>.from(e));
        await _earningBox.put(entry.id, entry);
      }
    }
    if (data['settings'] != null) {
      final s = data['settings'];
      if (s['companyName'] != null) await _settingBox.put('companyName', s['companyName']);
      if (s['taxYear'] != null) await _settingBox.put('taxYear', s['taxYear']);
    }
    await _initDefaults();
  }


  static Future<void> clearAllData() async {
    await _driverBox.clear();
    await _earningBox.clear();
    await _importHistoryBox.clear();
    await _driverAliasBox.clear();
    await _settingBox.clear();
    await _initDefaults();
  }


  // Import History & Alias
  static List<ImportHistoryModel> getImportHistory() =>
      _importHistoryBox.values.toList()..sort((a, b) => b.importDate.compareTo(a.importDate));

  static Future<void> saveImportHistory(ImportHistoryModel history) =>
      _importHistoryBox.put(history.id, history);

  static Future<void> deleteImportHistory(String id) async {
    final earnings = _earningBox.values.where((e) => e.id.startsWith(id)).toList();
    for (final e in earnings) { await _earningBox.delete(e.id); }
    await _importHistoryBox.delete(id);
  }

  static String? getDriverIdFromAlias(String alias) {
    final entry = _driverAliasBox.values.firstWhere(
      (a) => a.aliasName.toLowerCase() == alias.toLowerCase(),
      orElse: () => DriverAliasModel(aliasName: '', driverId: ''),
    );
    return entry.driverId.isEmpty ? null : entry.driverId;
  }

  static Future<void> saveDriverAlias(String alias, String driverId) =>
      _driverAliasBox.put(alias.toLowerCase(), DriverAliasModel(aliasName: alias, driverId: driverId));

  // Mapping Presets
  static List<MappingPreset> getMappingPresets() => _mappingPresetBox.values.toList();
  static Future<void> saveMappingPreset(MappingPreset preset) => _mappingPresetBox.put(preset.id, preset);
  static Future<void> deleteMappingPreset(String id) => _mappingPresetBox.delete(id);
}