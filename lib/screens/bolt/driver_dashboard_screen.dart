import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bolt_trips_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations_extension.dart';
import '../../utils/formatters.dart';
import '../../models/bolt_trip.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width > 600;
    final horizontalPadding = size.width * 0.05;

    final l10n = context.l10n;
    final tripsAsync = ref.watch(boltTripsProvider);
    final user = ref.watch(currentUserProvider);
    final driverName = user?.userMetadata?['company_name'] ?? user?.email ?? l10n.name;
    
    final summary = tripsAsync.maybeWhen(
      data: (trips) {
        final gross = trips.fold(0.0, (sum, t) => sum + t.priceTotal);
        final net = trips.fold(0.0, (sum, t) => sum + (t.netPayoutToDriver ?? 0.0));
        return (gross: gross, commission: gross - net, net: net);
      },
      orElse: () => (gross: 0.0, commission: 0.0, net: 0.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(boltTripsProvider.notifier).loadTrips(),
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) => RefreshIndicator(
          onRefresh: () => ref.read(boltTripsProvider.notifier).loadTrips(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isTablet) {
                // Tablet Layout: Two Columns
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Summary & Actions
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                        children: [
                          _buildSummaryCard(context, driverName, summary),
                          const SizedBox(height: 32),
                          _buildSyncAction(context, ref, tripsAsync),
                        ],
                      ),
                    ),
                    // Right Column: Trip List
                    Expanded(
                      flex: 3,
                      child: _buildTripListSection(context, trips, horizontalPadding),
                    ),
                  ],
                );
              }

              // Mobile Layout: Single Column
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                children: [
                  _buildSummaryCard(context, driverName, summary),
                  const SizedBox(height: 24),
                  _buildSyncAction(context, ref, tripsAsync),
                  const SizedBox(height: 32),
                  _buildTripListSection(context, trips, 0),
                ],
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.errorMessage(err.toString())}')),
      ),
    );
  }

  Widget _buildTripListSection(BuildContext context, List<BoltTrip> trips, double horizontalPadding) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      children: [
        Text(
          context.l10n.yourTrips,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (trips.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(context.l10n.noTripsFound),
            ),
          )
        else
          ...trips.map((trip) => _TripExpansionTile(trip: trip)),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String name, ({double gross, double commission, double net}) summary) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      elevation: 8,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.welcome,
              style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 14),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 40, color: Colors.white24),
            Row(
              children: [
                Expanded(child: _summaryItem(l10n.showBrutto, summary.gross, Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: _summaryItem(l10n.commissionLabel, summary.commission, Colors.white70)),
                const SizedBox(width: 8),
                Expanded(child: _summaryItem(l10n.showNetto, summary.net, Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        Text(
          formatSEK(value),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSyncAction(BuildContext context, WidgetRef ref, AsyncValue tripsAsync) {
    final isSyncing = tripsAsync.isRefreshing;
    final l10n = context.l10n;
    return ElevatedButton.icon(
      onPressed: isSyncing ? null : () => ref.read(boltTripsProvider.notifier).syncNow(),
      icon: isSyncing 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync),
      label: Text(isSyncing ? l10n.syncing : l10n.syncDataFromBolt),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _TripExpansionTile extends StatelessWidget {
  final BoltTrip trip;
  const _TripExpansionTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.drive_eta_rounded)),
        title: Text(
          trip.driverName ?? l10n.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const SizedBox(height: 4), 
            Text(
              trip.orderCreatedTimestamp != null 
                  ? DateFormat("MMM dd, yyyy  •  hh:mm a").format(trip.orderCreatedTimestamp!.toLocal()) 
                  : "Date Unknown", 
              style: TextStyle(fontSize: 12, color: Colors.grey[600])
            ), 
            Text("${l10n.ref}: ${trip.orderReference}", style: const TextStyle(fontSize: 11))
          ]
        ),
        trailing: Text(
          formatSEK(trip.netPayoutToDriver ?? 0.0),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 16),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          _breakdownRow(l10n.ridePrice, trip.priceTotal, isHeader: true),
          const SizedBox(height: 8),
          if ((trip.rawData?['dricks'] as num? ?? 0) > 0)
            _breakdownRow('(+) ${l10n.tips}', (trip.rawData?['dricks'] as num?).toDouble()),
          _breakdownRow('(-) ${l10n.boltCommission}', -(trip.priceTotal - trip.netEarnings)),
          _breakdownRow('(-) ${l10n.vat6}', -(trip.tax6Percent ?? 0.0)),
          _breakdownRow('(-) ${l10n.employerFee}', -(trip.employerFee3142 ?? 0.0)),
          const Divider(height: 24),
          _breakdownRow('(=) ${l10n.finalNetPayout}', trip.netPayoutToDriver ?? 0.0, isTotal: true),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double value, {bool isHeader = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHeader || isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : (value < 0 ? Colors.redAccent : null),
            ),
          ),
          Text(
            formatSEK(value),
            style: TextStyle(
              fontWeight: isHeader || isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : (value < 0 ? Colors.redAccent : null),
            ),
          ),
        ],
      ),
    );
  }
}
