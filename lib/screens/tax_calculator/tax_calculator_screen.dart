import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/calculation_service.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../models/driver.dart';
import '../../utils/formatters.dart';
import '../../utils/swedish_tax_constants.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

class TaxCalculatorScreen extends ConsumerStatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  ConsumerState<TaxCalculatorScreen> createState() =>
      _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends ConsumerState<TaxCalculatorScreen> {
  final _amountController = TextEditingController();
  double _commissionRate = 0.43;
  double _semesterRate = kSemesterSats12;
  PayrollResult? _result;
  double _inputAmount = 0;
  String? _selectedDriverId;

  void _calculate() {
    final amount = parseSwedishDouble(_amountController.text);
    if (amount <= 0) return;
    setState(() {
      _inputAmount = amount;
      _result = CalculationService.calculateFullPayroll(
        nettoIntakter: amount,
        commissionRate: _commissionRate,
        overrideSemesterRate: _semesterRate,
      );
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drivers = ref.watch(activeDriversProvider);
    final l10n = AppLocalizations.of(context)!;

    // Safety check: Ensure selected driver still exists
    if (_selectedDriverId != null && !drivers.any((d) => d.id == _selectedDriverId)) {
      _selectedDriverId = null;
    }

    final effectiveRate = _result != null && _inputAmount > 0
        ? _result!.totalLonekostnad / _inputAmount
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.taxCalculator)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      Icons.calculate_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.calculationBasis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: '${l10n.amount} (${l10n.showNetto.toLowerCase()})',
                      prefixIcon: const Icon(Icons.payments_rounded),
                      suffixText: 'kr',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calculate(),
                  ),
                  const SizedBox(height: 16),

                  // Commission rate selector
                  Text(
                    l10n.commissionRate,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 0.37, label: Text('37%')),
                      ButtonSegment(value: 0.43, label: Text('43%')),
                      ButtonSegment(value: 0.45, label: Text('45%')),
                    ],
                    selected: {_commissionRate},
                    onSelectionChanged: (v) {
                      setState(() {
                        _commissionRate = v.first;
                        _semesterRate = getSemesterRate(_commissionRate);
                      });
                      _calculate();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Semester rate selector
                  Text(
                    l10n.semesterRate,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 0.12, label: Text('12%')),
                      ButtonSegment(value: 0.13, label: Text('13%')),
                    ],
                    selected: {_semesterRate},
                    onSelectionChanged: (v) {
                      setState(() => _semesterRate = v.first);
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.result,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                    const Divider(height: 24),
                    _resultRow(
                      l10n.get('provision_incl_semester'),
                      _result!.provisionInklSemester,
                      theme,
                    ),
                    _resultRow(
                      l10n.get('excl_semester'),
                      _result!.exklSemester,
                      theme,
                    ),
                    _resultRow(
                      '${l10n.get('semester')} (${(_semesterRate * 100).toStringAsFixed(0)}%)',
                      _result!.semesterAmount,
                      theme,
                    ),
                    _resultRow(
                      '${l10n.get('fora')} 4.5%',
                      _result!.foraAmount,
                      theme,
                    ),
                    _resultRow(
                      '${l10n.get('arbetsgivaravgifter')} 31.42%',
                      _result!.arbetsgivaravgifter,
                      theme,
                    ),
                    const Divider(height: 20),
                    _resultRow(
                      l10n.get('total_lonekostnad'),
                      _result!.totalLonekostnad,
                      theme,
                      bold: true,
                    ),
                    _resultRow(
                      'Skatteavdrag (30%)',
                      -_result!.preliminaryTax,
                      theme,
                    ),
                    _resultRow(
                      'Utbetalas till konto',
                      _result!.takeHomePay,
                      theme,
                      bold: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0xFF2962FF).withValues(alpha: 0.1),
                          const Color(0xFF2962FF).withValues(alpha: 0.05),
                        ]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2962FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(children: [
                        Text(
                          l10n.get('andel_av_inkort'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPercent(effectiveRate),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2962FF),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Save to driver section
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      l10n.saveToDriver,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDriverId,
                      decoration: InputDecoration(
                        hintText: l10n.selectDriver,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      items: drivers
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(d.name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDriverId = v),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed:
                          _selectedDriverId == null ? null : _saveToDriver,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(l10n.save),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _saveToDriver() {
    if (_selectedDriverId == null || _result == null) return;

    final now = DateTime.now();
    final brutto = _inputAmount;
    // final netto = CalculationService.calculateNetto(brutto);
    // final moms = CalculationService.calculateMoms(brutto);

    ref.read(earningsProvider.notifier).addEarnings(
          driverId: _selectedDriverId!,
          weekNumber: _currentWeek(),
          month: now.month,
          year: now.year,
          platformId: 'bolt',
          bruttoAmount: brutto,
          dricks: 0,
        );
    ref.invalidate(monthlyPayrollProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.calculationSaved),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _currentWeek() {
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    return ((now.difference(jan1).inDays + jan1.weekday - 1) / 7).ceil();
  }

  Widget _resultRow(
    String label,
    double value,
    ThemeData theme, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          Text(
            formatSEK(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
              color: bold ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}