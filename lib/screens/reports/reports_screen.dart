import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/export_service.dart';
import '../../services/database_service.dart';
import '../../utils/formatters.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import '../../models/monthly_payroll.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final payrolls = ref.watch(
      monthlyPayrollProvider((month: _month, year: _year)),
    );
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    double totalBrutto = 0, totalLonekostnad = 0, totalDricks = 0, totalTakeHome = 0;
    final Map<String, double> platformTotals = {};
    
    for (final p in payrolls) {
      totalBrutto += p.totalBrutto;
      totalLonekostnad += p.totalLonekostnad;
      totalDricks += p.totalDricks;
      totalTakeHome += p.takeHomePay;
      p.platformBrutto.forEach((id, amount) {
        platformTotals[id] = (platformTotals[id] ?? 0) + amount;
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('monthly_report'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _month--;
                    if (_month < 1) {
                      _month = 12;
                      _year--;
                    }
                  });
                },
              ),
              Expanded(
                child: Text(
                  '${l10n.getMonthName(_month)} $_year',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _month++;
                    if (_month > 12) {
                      _month = 1;
                      _year++;
                    }
                  });
                },
              ),
            ]),
          ),

          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              _SummaryChip(
                label: l10n.totalRevenue,
                value: formatSEK(totalBrutto),
                color: theme.colorScheme.primary,
              ),
              _SummaryChip(
                label: l10n.payrollCost,
                value: formatSEK(totalLonekostnad),
                color: const Color(0xFFD32F2F),
              ),
              _SummaryChip(
                label: l10n.get('dricks_total'),
                value: formatSEK(totalDricks),
                color: const Color(0xFF2962FF),
              ),
              _SummaryChip(
                label: 'Utbetalning',
                value: formatSEK(totalTakeHome),
                color: const Color(0xFF34A853),
              ),
            ].map((w) => Expanded(child: w)).toList()),
          ),

          // Driver summary table
          if (payrolls.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                l10n.get('per_driver'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  columnSpacing: 16,
                  columns: [
                    DataColumn(label: Text(l10n.drivers)),
                    DataColumn(label: Text(l10n.showBrutto), numeric: true),
                    DataColumn(label: Text(l10n.provisionInclSemester), numeric: true),
                    DataColumn(label: Text(l10n.get('dricks_total')), numeric: true),
                    DataColumn(label: Text('Net Payout'), numeric: true),
                    DataColumn(label: Text(l10n.payrollCost), numeric: true),
                    DataColumn(label: Text(l10n.share), numeric: true),
                  ],
                  rows: payrolls.map((p) => DataRow(cells: [
                    DataCell(Text(
                      p.driverName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(formatNumber(p.totalBrutto))),
                    DataCell(Text(formatNumber(p.provisionInklSemester))),
                    DataCell(Text(formatNumber(p.totalDricks))),
                    DataCell(Text(
                      formatNumber(p.takeHomePay),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )),
                    DataCell(Text(formatNumber(p.totalLonekostnad))),
                    DataCell(Text(
                      formatPercent(p.effectiveRate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2962FF),
                      ),
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ],

          // Platform totals
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              l10n.get('per_platform'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              ...ref.watch(platformSettingsProvider).map((p) {
                final amount = platformTotals[p.id] ?? 0;
                if (amount == 0 && !(p.isLocked ?? false)) return const SizedBox.shrink();
                return _PlatformRow(
                  label: p.name,
                  amount: amount,
                  color: _getPlatformColor(p.id),
                );
              }),
              const Divider(height: 0),
              _PlatformRow(
                label: l10n.total,
                amount: platformTotals.values.fold(0.0, (a, b) => a + b),
                color: theme.colorScheme.primary,
                bold: true,
              ),
            ]),
          ),

          // Export buttons
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _exportPDF(payrolls),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(l10n.exportPdf),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _exporting ? null : () => _exportExcel(payrolls),
                  icon: const Icon(Icons.table_chart_rounded),
                  label: Text(l10n.exportExcel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ]),
          ),

          if (payrolls.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noDataForPeriod,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                ),
              ]),
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

  Future<void> _exportPDF(List<MonthlyPayroll> payrolls) async {
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context)!;
    final Map<String, String> labels = {
      'drivers': l10n.drivers,
      'amount': l10n.amount,
      'provision_incl_semester': l10n.provisionInclSemester,
      'dricks_total': l10n.get('dricks_total'),
      'payroll_cost': l10n.payrollCost,
      'revenue_by_platform': l10n.revenueByPlatform,
      'platform': l10n.platform,
      'total': l10n.total,
      'post': 'Post',
      'excl_semester': l10n.get('excl_semester'),
      'semester': l10n.semester,
      'fora': l10n.fora,
      'arbetsgivaravgifter': l10n.arbetsgivaravgifter,
      'share_of_revenue': l10n.shareOfRevenue,
      'show_netto': l10n.showNetto,
      'share': l10n.share,
      'monthly_report': l10n.get('monthly_report'),
    };

    try {
      final file = await ExportService.generateMonthlyPDF(
        payrolls: payrolls,
        monthName: l10n.getMonthName(_month),
        year: _year,
        companyName: DatabaseService.getCompanyName(),
        labels: labels,
      );
      if (mounted) {
        final monthName = l10n.getMonthName(_month);
        final companyName = DatabaseService.getCompanyName();

        await Share.shareXFiles(
          [XFile(file.path)], 
          subject: '${l10n.get('monthly_report')} - $monthName $_year',
          text: '${l10n.get('monthly_report')} ($companyName)',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.get('pdf_saved').split('{path}').first.trim()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                .get('error')
                .replaceAll('{error}', e.toString()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel(List<MonthlyPayroll> payrolls) async {
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context)!;
    final Map<String, String> labels = {
      'drivers': l10n.drivers,
      'amount': l10n.amount,
      'show_netto': l10n.showNetto,
      'dricks_total': l10n.get('dricks_total'),
      'provision_incl_semester': l10n.provisionInclSemester,
      'excl_semester': l10n.get('excl_semester'),
      'semester': l10n.semester,
      'fora': l10n.fora,
      'arbetsgivaravgifter': l10n.arbetsgivaravgifter,
      'payroll_cost': l10n.payrollCost,
      'share': l10n.share,
      'monthly_report': l10n.get('monthly_report'),
    };

    try {
      final file = await ExportService.generateMonthlyExcel(
        payrolls: payrolls,
        monthName: l10n.getMonthName(_month),
        year: _year,
        companyName: DatabaseService.getCompanyName(),
        labels: labels,
      );
      if (mounted) {
        final monthName = l10n.getMonthName(_month);
        final companyName = DatabaseService.getCompanyName();

        await Share.shareXFiles(
          [XFile(file.path)], 
          subject: '${l10n.get('monthly_report')} - $monthName $_year',
          text: '${l10n.get('monthly_report')} ($companyName)',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.get('excel_saved').split('{path}').first.trim()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                .get('error')
                .replaceAll('{error}', e.toString()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(top: BorderSide(color: color, width: 3)),
        ),
        child: Column(children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;
  
  const _PlatformRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: Text(
        formatSEK(amount),
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: bold ? color : null,
        ),
      ),
    );
  }
}