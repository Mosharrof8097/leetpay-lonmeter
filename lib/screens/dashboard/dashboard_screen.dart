import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/dashboard_widgets.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardDataProvider);
    final range = ref.watch(dashboardDateRangeProvider);
    final companyName = ref.watch(companyNameProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    debugPrint("DBA_DEBUG: Monitoring ${metrics.drivers.length} drivers. Driver Gross Map: ${metrics.driverGross}");

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: Hero(
            tag: 'app_logo',
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1), 
                  width: 1.5
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              companyName.toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 2.0,
                fontFamily: 'Montserrat',
              ),
            ),
            Container(
              height: 2,
              width: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
            onPressed: () => _selectDateRange(context, ref, range),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Manual refresh logic if needed
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Net Profit Card (Added as requested)
            NetProfitCard(amount: metrics.netRevenue),

            // Date range display bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d').format(range.start)} — ${DateFormat('MMM d, yyyy').format(range.end)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600, 
                      fontSize: 13
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PERIOD',
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Waterfall Flow Card
            RevenueWaterfallCard(
              gross: metrics.totalGross,
              tax: metrics.totalTax,
              fees: metrics.totalFees,
              net: metrics.netRevenue,
              dateRange: range,
            ),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildQuickAction(
                    context, 
                    'Import Data', 
                    Icons.cloud_upload_rounded, 
                    const Color(0xFF7ED957),
                    () => context.go('/import'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context, 
                    'API Sync', 
                    Icons.sync_rounded, 
                    Colors.orangeAccent,
                    () => context.go('/settings/integration'),
                  ),
                ],
              ),
            ),

            // Dynamic Platform Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Revenue by Platform',
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: metrics.platformGross.entries.map((e) => PlatformSummaryCard(
                  platformId: e.key,
                  gross: e.value,
                )).toList().cast<Widget>(),
              ),
            ),

            // Driver Monitor Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
              child: Text(
                'Driver Monitor',
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ...metrics.drivers.take(10).map((d) => DriverMonitorCard(
              name: d.name,
              gross: metrics.driverGross[d.id] ?? 0,
              isActive: d.isActive,
            )),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label, 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: TextStyle(
                      fontSize: 10, 
                      color: theme.colorScheme.onSurfaceVariant, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Text(
                    value, 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref, DateTimeRange current) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(dashboardDateRangeProvider.notifier).state = picked;
    }
  }
}
