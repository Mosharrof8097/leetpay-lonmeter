import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/earnings_entry.dart';
import '../../../utils/formatters.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import '../../widgets/platform_badge.dart';
import '../../widgets/payroll_summary_card.dart';
import '../../widgets/weekly_earnings_table.dart';
import '../../providers/bolt_trips_provider.dart';
import '../../providers/platform_config_provider.dart';


import '../../models/bolt_trip.dart';
import '../../models/platform_config.dart';
import '../../models/driver.dart';


class DriverDetailScreen extends ConsumerStatefulWidget {
  final String driverId;
  
  const DriverDetailScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driverProvider);
    final driver = drivers.where((d) => d.id == widget.driverId).firstOrNull;
    final l10n = AppLocalizations.of(context)!;

    
    if (driver == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.get('driver_not_found'))),
      );
    }

    final entries = ref.watch(driverMonthEarningsProvider(
      (driverId: widget.driverId, month: _selectedMonth, year: _selectedYear),
    ));
    final payroll = ref.watch(driverPayrollProvider(
      (driverId: widget.driverId, month: _selectedMonth, year: _selectedYear),
    ));

    final theme = Theme.of(context);

    final Map<String, double> platformTotals = {};
    double totalDricks = 0;
    for (final e in entries) {
      totalDricks += e.dricks;
      platformTotals[e.platformId] = (platformTotals[e.platformId] ?? 0) + e.nettoAmount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditDialog(context, driver),
            tooltip: l10n.get('edit'),
          ),
          IconButton(
            icon: Icon(
              driver.isActive ? Icons.toggle_on : Icons.toggle_off,
              color: driver.isActive ? Colors.green : Colors.grey,
              size: 32,
            ),
            onPressed: () => ref.read(driverProvider.notifier).toggleActive(driver.id),
            tooltip: driver.isActive ? l10n.get('deactivate') : l10n.get('activate'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [


          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _selectedMonth--;
                  if (_selectedMonth < 1) { _selectedMonth = 12; _selectedYear--; }
                }),
              ),
              Expanded(
                child: Text(
                  '${l10n.getMonthName(_selectedMonth)} $_selectedYear',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() {
                  _selectedMonth++;
                  if (_selectedMonth > 12) { _selectedMonth = 1; _selectedYear++; }
                }),
              ),
            ]),
          ),

          if (platformTotals.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: platformTotals.entries.map((e) {
                  final displayName = e.key[0].toUpperCase() + e.key.substring(1).toLowerCase();
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PlatformCard(
                      label: displayName,
                      amount: e.value,
                      color: _getPlatformColor(e.key),
                    ),
                  );
                }).toList(),

              ),
            ),

          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF2962FF)),
              title: Text(l10n.get('dricks_total')),
              trailing: Text(
                formatSEK(totalDricks),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2962FF)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: WeeklyEarningsTable(entries: entries),
          ),

          // --- BOLT DETAILED BREAKDOWN ---
          if (entries.any((e) => e.platformId == 'bolt'))
            _BoltBreakdownSection(
              driverId: widget.driverId,
              month: _selectedMonth,
              year: _selectedYear,
            ),

          if (payroll != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: PayrollSummaryCard(payroll: payroll),
            ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String id) {
    switch (id) {
      case 'bolt': return const Color(0xFF34A853);
      case 'uber': return const Color(0xFF424242);
      case 'wecab': return const Color(0xFF1565C0);
      default: return Colors.blueGrey;
    }
  }


  void _showEditDialog(BuildContext context, Driver driver) {
    final nameController = TextEditingController(text: driver.name);
    final commissionController = TextEditingController(text: (driver.commissionRate * 100).toStringAsFixed(1));
    final formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('edit_driver')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.get('name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l10n.get('required') : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: commissionController,
                decoration: InputDecoration(
                  labelText: '${l10n.get('commission')} (%)',
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.percent_rounded),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.get('required');
                  final val = double.tryParse(v);
                  if (val == null || val < 0 || val > 100) return '0-100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Note: Changes apply to future calculations.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.get('cancel'))),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updated = driver.copyWith(
                  name: nameController.text,
                  commissionRate: double.parse(commissionController.text) / 100,
                );
                ref.read(driverProvider.notifier).updateDriver(updated);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
}

class _BoltBreakdownSection extends ConsumerStatefulWidget {
  final String driverId;
  final int month;
  final int year;

  const _BoltBreakdownSection({
    required this.driverId,
    required this.month,
    required this.year,
  });

  @override
  ConsumerState<_BoltBreakdownSection> createState() => _BoltBreakdownSectionState();
}

class _BoltBreakdownSectionState extends ConsumerState<_BoltBreakdownSection> {
  bool _showVat = true;
  bool _showPlatformFee = true;
  bool _showHolidayPay = true;
  bool _showPension = true;

  double? _overrideVat;
  double? _overrideFee;
  double? _overrideShare;
  double? _overrideHoliday;
  double? _overridePension;


  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(boltTripsProvider);
    final configAsync = ref.watch(platformConfigProvider);
    final theme = Theme.of(context);

    return configAsync.when(
      data: (config) {
        if (config == null) return const SizedBox.shrink();

        return tripsAsync.when(
          data: (allTrips) {
            final drivers = ref.read(driverProvider);
            final driver = drivers.where((d) => d.id == widget.driverId).firstOrNull;
            if (driver == null) return const SizedBox.shrink();

            final trips = allTrips.where((t) {
              if (t.driverName != driver.name) return false;
              final date = t.orderCreatedTimestamp;
              return date != null && date.month == widget.month && date.year == widget.year;
            }).toList();

            if (trips.isEmpty) return const SizedBox.shrink();

            // Calculate dynamic totals based on user's defined rates and toggles
            double totalGross = 0;
            double totalTips = 0;
            for (var t in trips) {
              totalGross += t.priceTotal;
              totalTips += (t.rawData?['order_price']?['tips'] as num?)?.toDouble() ?? 0;
            }

            final vatRate = _showVat ? ((_overrideVat ?? config.taxPercent) / 100) : 0.0;
            final platformFeeRate = _showPlatformFee ? ((_overrideFee ?? config.platformFeePercent) / 100) : 0.0;
            final holidayRate = _showHolidayPay ? ((_overrideHoliday ?? config.holidayPayPercent) / 100) : 0.0;
            final pensionRate = _showPension ? ((_overridePension ?? config.pensionPercent) / 100) : 0.0;
            final shareRate = (_overrideShare ?? config.driverSharePercent) / 100;

            final vatAmount = totalGross * vatRate;
            final platformFeeAmount = totalGross * platformFeeRate;
            final revenue = totalGross - (vatAmount + platformFeeAmount);
            final driverBaseShare = revenue * shareRate;
            final holidayPay = driverBaseShare * holidayRate;
            final pension = (driverBaseShare + holidayPay) * pensionRate;
            final finalNet = driverBaseShare + holidayPay + pension + totalTips;

            return Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Live Calculation Worksheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),

                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _WorksheetToggle(
                          label: 'VAT (Moms)',
                          value: vatAmount,
                          isActive: _showVat,
                          onChanged: (v) => setState(() => _showVat = v!),
                          percent: _overrideVat ?? config.taxPercent,
                        ),
                        _WorksheetToggle(
                          label: 'Platform Fee',
                          value: platformFeeAmount,
                          isActive: _showPlatformFee,
                          onChanged: (v) => setState(() => _showPlatformFee = v!),
                          percent: _overrideFee ?? config.platformFeePercent,
                        ),
                        const Divider(height: 32),
                        _SummaryRow(label: 'Net Revenue', value: revenue, isBold: true),
                        const SizedBox(height: 16),
                        _WorksheetToggle(
                          label: 'Holiday Pay',
                          value: holidayPay,
                          isActive: _showHolidayPay,
                          onChanged: (v) => setState(() => _showHolidayPay = v!),
                          percent: _overrideHoliday ?? config.holidayPayPercent,
                          isDeduction: false,
                        ),
                        _WorksheetToggle(
                          label: 'Pension',
                          value: pension,
                          isActive: _showPension,
                          onChanged: (v) => setState(() => _showPension = v!),
                          percent: _overridePension ?? config.pensionPercent,
                          isDeduction: false,
                        ),
                        const Divider(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              _SummaryRow(label: 'Driver Base (${((_overrideShare ?? config.driverSharePercent)).toStringAsFixed(1)}%)', value: driverBaseShare),
                              const SizedBox(height: 4),
                              _SummaryRow(label: 'Total Tips (100% Driver)', value: totalTips, color: Colors.green),
                              const Divider(height: 24),
                              _SummaryRow(
                                label: 'Final Net Payout', 
                                value: finalNet, 
                                isBold: true, 
                                fontSize: 18, 
                                color: theme.colorScheme.primary
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Individual Trips (${trips.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trips.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final date = trip.orderCreatedTimestamp?.toLocal();
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.drive_eta, size: 16, color: Color(0xFF2E7D32)),
                        ),
                        title: Text(
                          formatSEK(trip.priceTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          date != null 
                              ? DateFormat("MMM dd, hh:mm a").format(date) 
                              : "No Date",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net: ${formatSEK(trip.netEarnings)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                            ),
                            if ((trip.rawData?['dricks'] as num? ?? 0) > 0)
                              Text(
                                'Tip: ${formatSEK((trip.rawData?['dricks'] as num?)?.toDouble() ?? 0.0)}',
                                style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _WorksheetToggle extends StatelessWidget {
  final String label;
  final double value;
  final bool isActive;
  final ValueChanged<bool?> onChanged;
  final double percent;
  final bool isDeduction;

  const _WorksheetToggle({
    required this.label,
    required this.value,
    required this.isActive,
    required this.onChanged,
    required this.percent,
    this.isDeduction = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: isActive, 
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            '${isDeduction ? "-" : "+"}${formatSEK(value)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? (isDeduction ? Colors.red.shade700 : Colors.green.shade700) : Colors.grey.shade400,
              decoration: isActive ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize - 1, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text(
          formatSEK(value),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  
  const _PlatformCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(top: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          FittedBox(
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(formatSEK(amount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}