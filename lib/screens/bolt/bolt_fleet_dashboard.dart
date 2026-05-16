import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bolt_trips_provider.dart';
import '../../utils/formatters.dart';

class BoltFleetDashboard extends ConsumerWidget {
  const BoltFleetDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(boltTripsProvider);
    final totalRevenue = ref.watch(boltTotalRevenueProvider);
    final totalTaxes = ref.watch(boltTotalTaxesProvider);
    final totalNetPayout = ref.watch(boltTotalNetPayoutProvider);
    final driverPayouts = ref.watch(boltDriverPayoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolt Fleet Automation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(boltTripsProvider.notifier).syncNow(),
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) => RefreshIndicator(
          onRefresh: () => ref.read(boltTripsProvider.notifier).syncNow(),
          child: CustomScrollView(
            slivers: [
              // Summary Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Total Ride Price', value: totalRevenue, isMain: true),
                          const Divider(height: 24),
                          _SummaryRow(label: 'Total Taxes (6% + 31.42%)', value: totalTaxes, color: Colors.redAccent),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Final Net Payout', 
                            value: totalNetPayout, 
                            color: Colors.green,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Sync Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(boltTripsProvider.notifier).syncNow(),
                    icon: const Icon(Icons.sync),
                    label: const Text('Manual Sync Now'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Driver Net Payouts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Driver List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final driverName = driverPayouts.keys.elementAt(index);
                    final payout = driverPayouts[driverName]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(driverName[0])),
                        title: Text(driverName),
                        subtitle: const Text('Final Net Payout (After Tax & Fees)'),
                        trailing: Text(
                          formatSEK(payout),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    );
                  },
                  childCount: driverPayouts.length,
                ),
              ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              ElevatedButton(
                onPressed: () => ref.read(boltTripsProvider.notifier).loadTrips(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool isMain;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.isMain = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMain ? 16 : 14,
            fontWeight: isMain || isBold ? FontWeight.bold : FontWeight.w500,
            color: color?.withValues(alpha: 0.8) ?? Colors.grey[600],
          ),
        ),
        Text(
          formatSEK(value),
          style: TextStyle(
            fontSize: isMain ? 24 : 18,
            fontWeight: isMain || isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? (isMain ? Theme.of(context).colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
