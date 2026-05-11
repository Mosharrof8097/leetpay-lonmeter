import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/earnings_entry.dart';
import '../../utils/formatters.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import '../../widgets/platform_badge.dart';
import '../../widgets/payroll_summary_card.dart';
import '../../widgets/weekly_earnings_table.dart';

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
    final platforms = ref.watch(platformSettingsProvider);
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.85),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  driver.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      CommissionBadge(rate: driver.commissionRate),
                      const SizedBox(width: 8),
                      Text(
                        driver.isActive ? l10n.get('active') : l10n.get('inactive'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),

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
                  final platform = platforms.firstWhere((p) => p.id == e.key, orElse: () => PlatformModel(id: e.key, name: e.key));
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PlatformCard(
                      label: platform.name,
                      amount: e.value,
                      color: _getPlatformColor(platform.id),
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

  void _showEditDialog(BuildContext context, dynamic driver) {
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
                decoration: InputDecoration(labelText: l10n.get('name')),
                validator: (v) => (v == null || v.isEmpty) ? l10n.get('required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: commissionController,
                decoration: InputDecoration(
                  labelText: '${l10n.get('commission')} (%)',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.get('required');
                  final val = double.tryParse(v);
                  if (val == null || val < 0 || val > 100) return '0-100';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Changes apply to future earnings only.',
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