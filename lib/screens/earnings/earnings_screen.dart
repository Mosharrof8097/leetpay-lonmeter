import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/calculation_service.dart';
import '../../models/driver.dart';
import '../../providers/payroll_provider.dart';
import '../../utils/formatters.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _selectedDriverId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  int _week = _currentWeek();

  final _bruttoController = TextEditingController();
  final _dricksController = TextEditingController();
  final _uberBruttoController = TextEditingController();
  final _feeController = TextEditingController();

  double _netto = 0;
  double _moms = 0;

  static int _currentWeek() {
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    return ((now.difference(jan1).inDays + jan1.weekday - 1) / 7).ceil();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _bruttoController.dispose();
    _dricksController.dispose();
    _uberBruttoController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _autoCalc() {
    final brutto = parseSwedishDouble(_bruttoController.text);
    final fee = parseSwedishDouble(_feeController.text);
    setState(() {
      _netto = CalculationService.calculateNetEarnings(brutto, feeAmount: fee);
      _moms = CalculationService.calculateMoms(brutto);
    });
  }

  @override
  Widget build(BuildContext context) {
    final platforms = ref.watch(platformSettingsProvider);
    final drivers = ref.watch(activeDriversProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_tabController == null || _tabController!.length != platforms.length) {
      _tabController?.dispose();
      _tabController = TabController(length: platforms.length, vsync: this);
    }

    final currentPlatform = platforms[_tabController!.index];
    
    // Safety check: Ensure selected driver still exists (prevents crash on deletion)
    if (_selectedDriverId != null && !drivers.any((d) => d.id == _selectedDriverId)) {
      _selectedDriverId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addEarning),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: platforms.length > 3,
          onTap: (_) => setState(() {}),
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: platforms.map((p) => Tab(
            text: p.name,
            icon: Icon(_getPlatformIcon(p.id), size: 18),
          )).toList(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period selectors
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _month,
                decoration: InputDecoration(labelText: l10n.get('month'), prefixIcon: const Icon(Icons.calendar_month_rounded)),
                items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1, child: Text(l10n.getMonthName(i + 1)))),
                onChanged: (v) => setState(() => _month = v!),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<int>(
                value: _year,
                decoration: InputDecoration(labelText: l10n.taxYear),
                items: List.generate(5, (i) => DropdownMenuItem(
                    value: DateTime.now().year - 2 + i,
                    child: Text('${DateTime.now().year - 2 + i}'))),
                onChanged: (v) => setState(() => _year = v!),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // Driver selector
          DropdownButtonFormField<String>(
            value: _selectedDriverId,
            decoration: InputDecoration(labelText: l10n.selectDriver, prefixIcon: const Icon(Icons.person_rounded)),
            items: drivers.map((d) => DropdownMenuItem(
                value: d.id,
                child: Row(children: [
                  Text(d.name),
                  const SizedBox(width: 8),
                  Text('(${d.commissionLabel})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ]))).toList(),
            onChanged: (v) => setState(() => _selectedDriverId = v),
            hint: Text(l10n.selectDriver),
          ),
          const SizedBox(height: 20),

          // Amount fields
          TextFormField(
            controller: _bruttoController,
            decoration: InputDecoration(
              labelText: '${l10n.amount} (${l10n.showBrutto})',
              prefixIcon: const Icon(Icons.payments_rounded),
              suffixText: 'kr',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate_rounded, color: Color(0xFF2962FF)),
                onPressed: _autoCalc,
                tooltip: l10n.get('auto_calculate'),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _autoCalc(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _feeController,
            decoration: InputDecoration(
              labelText: 'Platform Fee (Avgift)',
              prefixIcon: const Icon(Icons.money_off_rounded),
              suffixText: 'kr',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _autoCalc(),
          ),
          const SizedBox(height: 12),

          // Computed fields
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.showNetto, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(formatSEK(_netto), style: TextStyle(
                      fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2962FF).withValues(alpha: 0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Moms 6%', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(formatSEK(_moms), style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF2962FF))),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Tips
          TextFormField(
            controller: _dricksController,
            decoration: InputDecoration(
              labelText: l10n.get('dricks_total'),
              prefixIcon: const Icon(Icons.volunteer_activism_rounded),
              suffixText: 'kr',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Uber brutto (only for Uber tab)
          if (currentPlatform.id == 'uber')
            TextFormField(
              controller: _uberBruttoController,
              decoration: InputDecoration(
                labelText: 'Uber ${l10n.showBrutto.split(' ').last}',
                prefixIcon: const Icon(Icons.directions_car_rounded),
                suffixText: 'kr',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

          const SizedBox(height: 28),

          // Save button
          FilledButton.icon(
            onPressed: () => _save(currentPlatform.id, currentPlatform.name),
            icon: const Icon(Icons.save_rounded),
            label: Text(l10n.save),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String id) {
    switch (id) {
      case 'bolt': return Icons.electric_bolt_rounded;
      case 'uber': return Icons.directions_car_rounded;
      default: return Icons.local_taxi_rounded;
    }
  }

  Future<void> _save(String platformId, String platformName) async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectDriver), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final brutto = parseSwedishDouble(_bruttoController.text);
    if (brutto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterAmount), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    try {
      await ref.read(earningsProvider.notifier).addEarnings(
        driverId: _selectedDriverId!,
        weekNumber: _week,
        month: _month,
        year: _year,
        platformId: platformId,
        bruttoAmount: brutto,
        dricks: parseSwedishDouble(_dricksController.text),
        uberBrutto: parseSwedishDouble(_uberBruttoController.text),
        platformFee: parseSwedishDouble(_feeController.text),
      );
      
      // Reset fields ONLY on success
      _bruttoController.clear();
      _dricksController.clear();
      _uberBruttoController.clear();
      _feeController.clear();
      setState(() { _netto = 0; _moms = 0; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('earning_saved')
              .replaceAll('{platform}', platformName)
              .replaceAll('{week}', _week.toString())),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF34A853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
