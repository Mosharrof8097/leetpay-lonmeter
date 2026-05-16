import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/company_trips_provider.dart';
import '../../models/bolt_trip.dart';
import '../../l10n/app_localizations_extension.dart';
import '../../utils/formatters.dart';

class BoltAdminDashboard extends ConsumerWidget {
  const BoltAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(companyTripsProvider);
    final summary = ref.watch(companySummaryProvider);
    final driverSummaries = ref.watch(driverSummariesProvider);
    final groupedTrips = ref.watch(groupedByDriverProvider);

    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, ref, tripsAsync),
          
          // Company Overview Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _CompanyOverviewCard(summary: summary),
            ),
          ),

          // Action Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.boltFleetAutomation,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.totalActive(driverSummaries.length),
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Driver List
          tripsAsync.when(
            data: (trips) => trips.isEmpty 
              ? SliverFillRemaining(child: Center(child: Text(l10n.noTripsFound)))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final driverName = driverSummaries.keys.elementAt(index);
                      final driverSum = driverSummaries[driverName]!;
                      final trips = groupedTrips[driverName]!;
                      return _DriverExpansionCard(
                        driverName: driverName,
                        summary: driverSum,
                        trips: trips,
                      );
                    },
                    childCount: driverSummaries.length,
                  ),
                ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('${l10n.errorMessage(err.toString())}'))),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, AsyncValue tripsAsync) {
    final isSyncing = tripsAsync.isRefreshing;
    final l10n = context.l10n;
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(l10n.adminDashboard, style: const TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: isSyncing 
            ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.sync_rounded),
                onPressed: () => ref.read(companyTripsProvider.notifier).syncBoltData(),
                tooltip: l10n.syncDataFromBolt,
              ),
        ),
      ],
    );
  }
}

class _CompanyOverviewCard extends StatelessWidget {
  final ({double gross, double commission, double taxes, double net}) summary;

  const _CompanyOverviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(context, l10n.totalRevenue, summary.gross, isMain: true),
                _buildSummaryItem(context, l10n.showNetto, summary.net, color: Colors.green, isMain: true),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(context, l10n.boltCommission, summary.commission, color: Colors.orange),
                _buildSummaryItem(context, l10n.arbetsgivaravgifter, summary.taxes, color: Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double value, {Color? color, bool isMain = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: isMain ? 14 : 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          formatSEK(value),
          style: TextStyle(
            fontSize: isMain ? 22 : 18,
            fontWeight: FontWeight.w900,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _DriverExpansionCard extends StatelessWidget {
  final String driverName;
  final ({double net, int tripCount}) summary;
  final List<BoltTrip> trips;

  const _DriverExpansionCard({
    required this.driverName,
    required this.summary,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(driverName[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${l10n.totalActive(summary.tripCount)} • Net: ${formatSEK(summary.net)}'),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          ...trips.map((trip) => _TripListTile(trip: trip)),
        ],
      ),
    );
  }
}

class _TripListTile extends StatelessWidget {
  final BoltTrip trip;
  const _TripListTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_taxi_rounded, size: 20, color: Colors.blueGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.ref}: ${trip.orderReference}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  trip.orderCreatedTimestamp?.toLocal().toString().split('.')[0] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatSEK(trip.netPayoutToDriver ?? 0.0),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
              ),
              Text(
                '${l10n.priceTotal}: ${formatSEK(trip.priceTotal)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
