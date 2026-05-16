import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bolt_trip.dart';
import 'supabase_service.dart';

class FleetApiService {
  static final _supabase = Supabase.instance.client;
  static const String _boltAuthUrl = 'https://oidc.bolt.eu/token';
  static const String _boltBaseUrl = 'https://node.bolt.eu/fleet-integration-gateway';
  static const String _boltScope = 'fleet-integration:api';

  /// Performs a full sync from Bolt using stored credentials
  /// [startDate] and [endDate] are optional. Defaults to last 30 days.
  static Future<void> syncBoltData({DateTime? startDate, DateTime? endDate}) async {
    await _performSync(startDate: startDate, endDate: endDate);
  }

  // Legacy alias for older code
  static Future<void> triggerSync({DateTime? startDate, DateTime? endDate}) => 
      _performSync(startDate: startDate, endDate: endDate);

  static Future<List<BoltTrip>> getSyncedTrips() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('earnings_raw')
        .select()
        .eq('owner_id', userId)
        .eq('platform', 'bolt');  // lowercase — matches what we save
    
    return (response as List).map((e) => BoltTrip.fromJson(e)).toList();
  }

  static Future<void> _performSync({DateTime? startDate, DateTime? endDate}) async {
    // 1. Fetch credentials from Supabase
    final creds = await SupabaseService.fetchCredentials();
    if (creds == null || creds['client_id'] == null || creds['client_secret'] == null) {
      throw Exception('Bolt credentials not found in Settings');
    }

    final clientId = creds['client_id'];
    final clientSecret = creds['client_secret'];
    String? fleetId = creds['fleet_id'];

    // 2. Get Access Token
    final String accessToken = await _getAccessToken(clientId, clientSecret);

    // 3. Discover Fleet ID if missing
    if (fleetId == null || fleetId.isEmpty) {
      fleetId = await _discoverFleetId(accessToken);
      await SupabaseService.saveCredentials(
        clientId: clientId,
        clientSecret: clientSecret,
        fleetId: fleetId,
      );
    }

    // 4. Fetch ALL Trips with pagination (no more 100-trip limit!)
    final trips = await _fetchAllTrips(accessToken, fleetId, startDate: startDate, endDate: endDate);
    debugPrint('BoltAPI: Total trips fetched across all pages: ${trips.length}');

    // 5. Store in Unified Ledger (earnings_raw) — single source of truth
    await _storeInUnifiedLedger(trips);
    debugPrint('BoltAPI: ✅ Sync complete. ${trips.length} trips processed into earnings_raw.');
  }

  static Future<String> _getAccessToken(String id, String secret) async {
    final response = await http.post(
      Uri.parse(_boltAuthUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': id,
        'client_secret': secret,
        'scope': _boltScope,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to authenticate with Bolt: ${response.body}');
    }
  }

  static Future<String> _discoverFleetId(String token) async {
    // Note: Bolt API might use company_id from settings or a separate lookup
    // For now, we return empty or try to get it from settings if available
    return ''; 
  }

  /// Fetches ALL trips using pagination and 30-day chunking
  static Future<List<BoltTrip>> _fetchAllTrips(
    String token, 
    String fleetId, 
    {DateTime? startDate, DateTime? endDate}
  ) async {
    final now = endDate ?? DateTime.now();
    final from = startDate ?? now.subtract(const Duration(days: 30));
    final List<BoltTrip> allTrips = [];

    debugPrint('BoltAPI: Fetching ALL orders for fleet $fleetId from ${from.toIso8601String()} to ${now.toIso8601String()}');

    // Bolt API limits date range to 31 days. We must chunk the requests into smaller periods.
    DateTime currentStart = from;
    while (currentStart.isBefore(now)) {
      DateTime currentEnd = currentStart.add(const Duration(days: 30));
      if (currentEnd.isAfter(now)) {
        currentEnd = now;
      }

      debugPrint('BoltAPI: --- Fetching Chunk: ${currentStart.toIso8601String()} to ${currentEnd.toIso8601String()} ---');

      const int pageSize = 100;
      int offset = 0;

      while (true) {
        final response = await http.post(
          Uri.parse('$_boltBaseUrl/fleetIntegration/v1/getFleetOrders'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'company_ids': [int.tryParse(fleetId) ?? 0],
            'start_ts': currentStart.millisecondsSinceEpoch ~/ 1000,
            'end_ts': currentEnd.millisecondsSinceEpoch ~/ 1000,
            'limit': pageSize,
            'offset': offset,
          }),
        );

        debugPrint('BoltAPI: Page offset=$offset → Status: ${response.statusCode}');
        
        if (response.statusCode != 200) {
          debugPrint('BoltAPI: Fetch failed at offset $offset: ${response.body}');
          // If we hit an error (like INVALID_DATE_RANGE), break out of this chunk but continue next
          break;
        }

        final decoded = jsonDecode(response.body);
        
        final List pageData = decoded['data']?['orders'] ?? decoded['orders'] ?? [];
        debugPrint('BoltAPI: Got ${pageData.length} orders at offset $offset');

        if (pageData.isEmpty) break; // No more data in this chunk

        allTrips.addAll(pageData.map((json) => BoltTrip.fromJson(json)));

        // If we got fewer than pageSize, we've reached the last page for this chunk
        if (pageData.length < pageSize) break;
        
        offset += pageSize;
      }

      // Move to the next chunk
      currentStart = currentEnd.add(const Duration(seconds: 1)); 
    }

    debugPrint('BoltAPI: ✅ Total orders fetched across all chunks: ${allTrips.length}');
    return allTrips;
  }

  static Future<void> _storeInUnifiedLedger(List<BoltTrip> trips) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || trips.isEmpty) return;

    // 1. Fetch drivers for matching
    final drivers = await SupabaseService.fetchDrivers();
    final Map<String, String> driverCache = {
      for (var d in drivers) d.name.toLowerCase().trim(): d.id
    };

    final List<Map<String, dynamic>> dataToUpsert = [];

    for (final trip in trips) {
      final ref = trip.orderReference; 
      if (ref.isEmpty) continue; 

      // Store ALL trips — including cancelled ones (they show with kr 0 and CANCELLED status)
      // This gives accurate trip history. Dashboard can filter by status if needed.
      // Only skip if the reference is empty (invalid trip)
      final orderStatus = (trip.orderStatus ?? '').toLowerCase();
      final isCancelled = orderStatus.contains('cancel') || orderStatus.contains('reject');
      
      // If cancelled AND no money, still save but mark clearly
      // If has money, always save
      if (trip.priceTotal <= 0 && trip.dricks <= 0 && !isCancelled) {
        // Truly empty record with no status — skip
        debugPrint('DBA_DEBUG: Skipping empty trip $ref (no price, no tips, no cancel status)');
        continue;
      }

      final driverName = trip.driverName ?? '';
      final nameKey = driverName.toLowerCase().trim();
      final uuidKey = trip.driverUuid;

      String? matchedDriverId;

      // Try match by UUID first
      if (uuidKey != null) {
        try {
          matchedDriverId = drivers.firstWhere((d) => d.boltUuid == uuidKey).id;
        } catch (_) {}
      }

      // Fallback to Name match
      if (matchedDriverId == null && nameKey.isNotEmpty) {
        matchedDriverId = driverCache[nameKey];
      }

      // Auto-create driver if not found
      if (matchedDriverId == null && driverName.isNotEmpty) {
        try {
          final newDriver = await _supabase.from('drivers').insert({
            'owner_id': userId,
            'name': driverName,
            'bolt_uuid': uuidKey,
          }).select().single();
          matchedDriverId = newDriver['id'];
          driverCache[nameKey] = matchedDriverId!;
          debugPrint('DBA_DEBUG: Auto-created driver: $driverName');
        } catch (e) {
          debugPrint('DBA_DEBUG: Error auto-creating driver: $e');
        }
      }

      // Improved price extraction from model
      final brutto = trip.priceTotal;
      final net = trip.netEarnings;
      final tips = trip.dricks;
      final moms = trip.tax6Percent ?? (brutto * 0.0566);

      final tripDate = trip.orderCreatedTimestamp;
      final dateStr = tripDate?.toIso8601String().split('T')[0]
          ?? DateTime.now().toIso8601String().split('T')[0];

      // Calculate week, month, year from trip date
      int? weekNum, month, year;
      if (tripDate != null) {
        month = tripDate.month;
        year = tripDate.year;
        // ISO week calculation
        final dayOfYear = tripDate.difference(DateTime(tripDate.year, 1, 1)).inDays + 1;
        weekNum = ((dayOfYear - tripDate.weekday + 10) / 7).floor();
      }

      dataToUpsert.add({
        'id': 'bolt_$ref',           // Deterministic — safe to re-sync
        'owner_id': userId,
        'driver_id': matchedDriverId,
        'driver_name': driverName,
        'brutto_amount': brutto,
        'net_amount': net,
        'moms_amount': moms,
        'platform_fee': (brutto > 0) ? (brutto - net) : 0,
        'dricks': tips,
        'platform': 'bolt',
        'source': 'bolt_api',
        'date': dateStr,
        'week_number': weekNum,
        'entry_month': month,
        'entry_year': year,
        'reference': ref,
        'raw_data': trip.rawData,
      });
    }

    if (dataToUpsert.isNotEmpty) {
      try {
        // Upsert: safe to call repeatedly (idempotent)
        await _supabase
            .from('earnings_raw')
            .upsert(dataToUpsert, onConflict: 'id');
        debugPrint('BoltAPI: ✅ Upserted ${dataToUpsert.length} trips to earnings_raw');
      } catch (e) {
        debugPrint('BoltAPI: ❌ ERROR saving to earnings_raw: $e');
      }
    }
  }
}
