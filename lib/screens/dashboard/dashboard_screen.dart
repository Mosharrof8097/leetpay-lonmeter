import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/earnings_entry.dart';
import '../../utils/formatters.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import '../../widgets/earnings_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    final drivers = ref.watch(driverProvider);
    final earnings = ref.watch(earningsProvider);
    final payrolls = ref.watch(monthlyPayrollProvider((month: month, year: year)));
    final totalRevenue = ref.watch(totalRevenueProvider((month: month, year: year)));
    final avgComm = ref.watch(avgCommissionProvider((month: month, year: year)));
    final totalProfit = ref.watch(totalProfitProvider((month: month, year: year)));
    final avgMargin = ref.watch(avgProfitMarginProvider((month: month, year: year)));
    final companyName = ref.watch(companyNameProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Speedometer Gradient Colors
    const chartGradient = [Color(0xFFB5E61D), Color(0xFF22B14C)];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Text(
              l10n.appTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        title: Text(
          companyName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_rounded),
            onPressed: () => context.push('/tax-calculator'),
            tooltip: l10n.taxCalculator,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(driverProvider.notifier).refresh();
          await ref.read(earningsProvider.notifier).refresh();
          await ref.read(companyNameProvider.notifier).refresh();
          ref.invalidate(platformSettingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Header gradient section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: chartGradient,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.getMonthName(month)} $year',
                    style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatSEK(totalRevenue),
                    style: const TextStyle(
                      color: Colors.black, 
                      fontSize: 36, 
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.totalRevenue,
                    style: const TextStyle(
                      color: Colors.black54, 
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Summary cards row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: EarningsCard(
                      title: l10n.activeDrivers,
                      amount: drivers.where((d) => d.isActive).length.toDouble(),
                      subtitle: l10n.totalActive(drivers.length),
                      isCurrency: false,
                    ),
                  ),
                  Expanded(
                    child: EarningsCard(
                      title: l10n.avgCommission,
                      amount: avgComm * 100,
                      icon: Icons.percent_rounded,
                      color: const Color(0xFF2962FF),
                      subtitle: l10n.shareOfRevenueInfo,
                      isCurrency: false,
                      suffix: '%',
                    ),
                  ),
                ],
              ),
            ),

            // Analytics Row (Profit Tracking)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: EarningsCard(
                      title: l10n.netProfit,
                      amount: totalProfit,
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF00C853),
                      subtitle: l10n.afterAllTaxes,
                      isCurrency: true,
                    ),
                  ),
                  Expanded(
                    child: EarningsCard(
                      title: l10n.profitMargin,
                      amount: avgMargin * 100,
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF64DD17),
                      subtitle: l10n.avgPerDriver,
                      isCurrency: false,
                      suffix: '%',
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/earnings'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addEarning),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/reports'),
                    icon: const Icon(Icons.description_rounded),
                    label: Text(l10n.report),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ]),
            ),

            // Revenue by platform chart
            if (earnings.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.revenueByPlatform,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _PlatformBarChart(month: month, year: year, gradient: chartGradient),
            ],

            // Recent payrolls
            if (payrolls.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  l10n.payrollOverview,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...payrolls.take(5).map((p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      p.driverName.isNotEmpty ? p.driverName[0] : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary, 
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.driverName, 
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CommissionBadgeMini(rate: p.commissionRate),
                    ],
                  ),
                  subtitle: Text(
                    '${l10n.payrollCost}: ${formatSEK(p.totalLonekostnad)}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Text(
                            formatSEK(p.netProfit),
                            style: const TextStyle(
                              color: Color(0xFF00C853), 
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${l10n.margin}: ${formatPercent(p.profitMargin)}',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlatformBarChart extends ConsumerWidget {
  final int month, year;
  final List<Color> gradient;
  
  const _PlatformBarChart({
    required this.month, 
    required this.year,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);
    final platforms = ref.watch(platformSettingsProvider);
    
    final monthEntries = earnings
        .where((e) => e.month == month && e.year == year)
        .toList();
    
    final Map<String, double> platformData = {};
    for (final e in monthEntries) {
      platformData[e.platformId] = (platformData[e.platformId] ?? 0) + e.bruttoAmount;
    }
    
    final displayPlatforms = platforms.where((p) => platformData.containsKey(p.id) || (p.isLocked ?? false)).toList();
    
    double maxVal = 0;
    if (platformData.isNotEmpty) {
      maxVal = platformData.values.reduce((a, b) => a > b ? a : b);
    }
    if (maxVal == 0) maxVal = 1000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            maxY: maxVal * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final name = displayPlatforms[groupIndex].name;
                  return BarTooltipItem(
                    '$name\n${formatSEK(rod.toY)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= displayPlatforms.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        displayPlatforms[idx].name, 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, 
                  reservedSize: 50,
                  getTitlesWidget: (v, _) => Text(
                    formatNumber(v), 
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true, 
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(displayPlatforms.length, (i) {
              final p = displayPlatforms[i];
              return _makeBar(i, platformData[p.id] ?? 0);
            }),
          )),
        ),
      ),
    );
  }

  BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}
class _CommissionBadgeMini extends StatelessWidget {
  final double rate;
  const _CommissionBadgeMini({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF22B14C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF22B14C).withValues(alpha: 0.3)),
      ),
      child: Text(
        '${(rate * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Color(0xFF22B14C),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
