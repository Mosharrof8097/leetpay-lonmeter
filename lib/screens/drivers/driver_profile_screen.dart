import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../providers/driver_provider.dart';
import '../../providers/bolt_trips_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/formatters.dart';

class DriverProfileScreen extends ConsumerWidget {
  final String driverId;
  const DriverProfileScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(driverProvider);
    final driver = drivers.isEmpty ? null : drivers.firstWhere((d) => d.id == driverId, orElse: () => drivers.first);
    
    if (driver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tripsAsync = ref.watch(boltTripsProvider);
    final dateRange = ref.watch(dashboardDateRangeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBolt = driver.platform.toLowerCase() == 'bolt';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: tripsAsync.when(
        data: (allTrips) {
          // Filter trips for THIS driver (UUID match OR name match) and Date Range
          final driverTrips = allTrips.where((t) {
            final bool matchesId = t.driverUuid != null && t.driverUuid == driver.id;
            final bool matchesName = (t.driverName ?? '').toLowerCase().trim() == driver.name.toLowerCase().trim();
            final matchesDriver = matchesId || matchesName;
            
            if (t.orderCreatedTimestamp == null) return false;

            // Normalize dates to ignore time components
            final tripDateStr = t.orderCreatedTimestamp!.toIso8601String().split('T')[0];
            final startStr = dateRange.start.toIso8601String().split('T')[0];
            final endStr = dateRange.end.toIso8601String().split('T')[0];
            
            final matchesDate = tripDateStr.compareTo(startStr) >= 0 && tripDateStr.compareTo(endStr) <= 0;
            return matchesDriver && matchesDate;
          }).toList();

          // Calculate Real Metrics
          double totalGross = 0;
          double totalNet = 0;
          double totalTips = 0;
          for (var t in driverTrips) {
            totalGross += t.priceTotal;
            totalNet += (t.netPayoutToDriver ?? 0);
            totalTips += t.dricks; // Uses the hardened tip field
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, driver, isDark, isBolt),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        child: _buildFinancialOverview(totalGross, totalNet, totalTips),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _buildSavingsSection(driver),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildVehicleCard(driverTrips, isDark),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        child: _buildTripHistorySection(driverTrips, isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic driver, bool isDark, bool isBolt) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isBolt 
                ? [const Color(0xFF7ED957), const Color(0xFF2E7D32)]
                : [const Color(0xFF424242), const Color(0xFF212121)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -30,
                top: -30,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.bolt_rounded, size: 200, color: Colors.white),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Text(
                        driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      driver.name,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        driver.platform.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(double gross, double net, double tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FINANCIAL SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Revenue', formatSEK(gross), Icons.account_balance_wallet_rounded, Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Net Payout', formatSEK(net), Icons.payments_rounded, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Tips', formatSEK(tips), Icons.stars_rounded, Colors.orangeAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Status', 'Active', Icons.check_circle_rounded, Colors.purpleAccent)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsSection(dynamic driver) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BENEFIT SAVINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          _buildSavingRow('Holiday Pay (12%)', driver.totalHolidaySaved ?? 0.0, Colors.orangeAccent),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildSavingRow('Pension/Flora (4.5%)', driver.totalPensionSaved ?? 0.0, Colors.blueAccent),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildSavingRow('Tuition Fees', 0.0, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildSavingRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(
          formatSEK(amount),
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(List<dynamic> trips, bool isDark) {
    // Try to get vehicle info from the latest trip's raw data
    String vehicleModel = 'Standard Vehicle';
    String licensePlate = 'N/A';
    
    if (trips.isNotEmpty) {
      final latestTrip = trips.first;
      vehicleModel = latestTrip.rawData?['vehicle_model'] ?? 'Standard Vehicle';
      licensePlate = latestTrip.rawData?['vehicle_license_plate'] ?? 'N/A';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blueGrey.withAlpha(25), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.directions_car_rounded, color: Colors.blueGrey, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VEHICLE DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(vehicleModel, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16)),
                Text('Plate: $licensePlate', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistorySection(List<dynamic> trips, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT TRIPS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        if (trips.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No trips found.'))),
        ...trips.map((t) {
          final rawStatus = (t.orderStatus ?? 'Completed').toString().toLowerCase();
          final isCancelled = rawStatus.contains('cancel') || rawStatus.contains('reject') || rawStatus.contains('fail');
          
          final statusLabel = isCancelled ? 'CANCELLED' : 'COMPLETED';
          final statusColor = isCancelled ? Colors.redAccent : Colors.green;
          
          return _buildTripItem(
            'Order #${t.orderReference.substring(t.orderReference.length > 6 ? t.orderReference.length - 6 : 0)}', 
            formatSEK(t.priceTotal), 
            statusLabel, 
            statusColor, 
            isDark,
            tip: t.dricks,
          );
        }),
      ],
    );
  }

  Widget _buildTripItem(String title, String amount, String status, Color color, bool isDark, {double tip = 0}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status, 
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                    ),
                  ),
                  if (tip > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TIP: ${formatSEK(tip)}', 
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 9),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Text(amount, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 15, color: color == Colors.redAccent ? Colors.grey : null)),
        ],
      ),
    );
  }
}
