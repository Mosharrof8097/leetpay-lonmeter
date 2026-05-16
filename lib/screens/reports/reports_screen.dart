import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:printing/printing.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/reports_provider.dart';
import '../../utils/formatters.dart';
import '../../models/monthly_payroll.dart';
import '../../services/export_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Check if we have settled reports for this period
    final settledAsync = ref.watch(settledReportsProvider((month: _month, year: _year)));
    final payrolls = ref.watch(monthlyPayrollProvider((month: _month, year: _year)));

    return settledAsync.when(
      data: (settledData) {
        final bool isSettled = settledData.isNotEmpty;
        
        double totalGross = 0;
        double totalProfit = 0;
        double totalPayout = 0;

        if (isSettled) {
          for (final s in settledData) {
            totalGross += (s['brutto'] as num).toDouble();
            totalProfit += (s['profit'] as num).toDouble();
            totalPayout += (s['payout'] as num).toDouble();
          }
        } else {
          for (final p in payrolls) {
            totalGross += p.totalBrutto;
            totalProfit += p.netProfit;
            totalPayout += p.takeHomePay;
          }
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text('REPORTS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
            centerTitle: true,
            actions: [
              if (isSettled)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    label: const Text('FINALIZED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: const Color(0xFF2E7D32),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(theme, isDark),
                      const SizedBox(height: 24),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: _buildMainMetrics(totalGross, totalProfit, totalPayout),
                      ),
                      const SizedBox(height: 32),
                      isSettled 
                        ? _buildSettledTable(settledData, isDark, theme)
                        : _buildDetailedReportTable(payrolls, isDark, theme),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _exportReport(context, ref, isSettled ? settledData : payrolls),
            backgroundColor: const Color(0xFF7ED957),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(isSettled ? 'EXPORT PDF' : 'PREVIEW PDF', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildSettledTable(List<Map<String, dynamic>> data, bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SETTLED RECORDS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.grey)),
            const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 14,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('DRIVER')),
                DataColumn(label: Text('BRUTTO')),
                DataColumn(label: Text('NET REV')),
                DataColumn(label: Text('TAX')),
                DataColumn(label: Text('SOC.FEES')),
                DataColumn(label: Text('PAYOUT')),
                DataColumn(label: Text('PROFIT')),
              ],
              rows: data.map((s) {
                return DataRow(
                  cells: [
                    DataCell(Text(s['drivers']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800))),
                    DataCell(Text(formatSEK((s['brutto'] as num).toDouble()))),
                    DataCell(Text(formatSEK((s['net_revenue'] as num).toDouble()))),
                    DataCell(Text(formatSEK((s['tax'] as num).toDouble()), style: const TextStyle(color: Colors.redAccent))),
                    DataCell(Text(formatSEK((s['soc_fees'] as num).toDouble()), style: const TextStyle(color: Colors.orangeAccent))),
                    DataCell(Text(formatSEK((s['payout'] as num).toDouble()), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900))),
                    DataCell(Text(formatSEK((s['profit'] as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w900))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportReport(BuildContext context, WidgetRef ref, List<dynamic> payrolls) async {
    if (payrolls.isEmpty) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfFile = await ExportService.generateMonthlyPDF(
        payrolls: payrolls.cast<MonthlyPayroll>(),
        monthName: _getMonthName(_month),
        year: _year,
        companyName: 'Lönmeter AB',
        labels: {
          'drivers': 'Drivers',
          'amount': 'Brutto',
          'payroll_cost': 'Cost',
          'monthly_report': 'Report',
          'summary': 'Summary',
        },
      );

      if (mounted) {
        // Safe way to pop the dialog
        Navigator.of(context, rootNavigator: true).pop(); 
        
        await Printing.layoutPdf(
          onLayout: (format) => pdfFile.readAsBytes(),
          name: 'Monthly_Report_${_getMonthName(_month)}_$_year',
        );
      }
    } catch (e) {
      if (mounted) {
        // Ensure dialog is closed even on error if possible
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  Widget _buildDetailedReportTable(List<MonthlyPayroll> payrolls, bool isDark, ThemeData theme) {
    if (payrolls.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('No data for this period', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DETAILED ANALYTICS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.grey)),
            const Icon(Icons.table_chart_rounded, color: Colors.grey, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 14,
              horizontalMargin: 12,
              headingRowHeight: 50,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              headingTextStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
              columns: const [
                DataColumn(label: Text('DRIVER')),
                DataColumn(label: Text('BRUTTO')),
                DataColumn(label: Text('NET REV')),
                DataColumn(label: Text('MOMS (6%)')),
                DataColumn(label: Text('SOC. FEES')),
                DataColumn(label: Text('TAX (30%)')),
                DataColumn(label: Text('PAYOUT')),
                DataColumn(label: Text('PROFIT')),
              ],
              rows: payrolls.map((p) {
                final double netRev = p.totalBrutto / 1.06;
                final double moms = p.totalBrutto - netRev;
                final double socFees = p.totalLonekostnad * (31.42 / 131.42);
                final double personalTax = (p.totalLonekostnad - socFees) * 0.30;
                final double payout = (p.totalLonekostnad - socFees) - personalTax;
                final double profit = p.totalBrutto * 0.15;

                return DataRow(
                  key: ValueKey('report_${p.driverId}_${_month}_$_year'),
                  cells: [
                    DataCell(Text(p.driverName, style: const TextStyle(fontWeight: FontWeight.w800))),
                    DataCell(Text(formatSEK(p.totalBrutto))),
                    DataCell(Text(formatSEK(netRev))),
                    DataCell(Text(formatSEK(moms), style: const TextStyle(color: Colors.blueAccent))),
                    DataCell(Text(formatSEK(socFees), style: const TextStyle(color: Colors.orangeAccent))),
                    DataCell(Text(formatSEK(personalTax), style: const TextStyle(color: Colors.redAccent))),
                    DataCell(Text(formatSEK(payout), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900))),
                    DataCell(Text(formatSEK(profit), style: const TextStyle(fontWeight: FontWeight.w900))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() {
              if (_month == 1) {
                _month = 12;
                _year--;
              } else {
                _month--;
              }
            }),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${_getMonthName(_month).toUpperCase()} $_year',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          IconButton(
            onPressed: () => setState(() {
              if (_month == 12) {
                _month = 1;
                _year++;
              } else {
                _month++;
              }
            }),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics(double gross, double profit, double cost) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7ED957), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7ED957).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              const Text('TOTAL GROSS REVENUE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatSEK(gross), style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSmallMetricCard('Net Profit', formatSEK(profit), Icons.trending_up_rounded, Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallMetricCard('Payroll Cost', formatSEK(cost), Icons.account_tree_rounded, Colors.orangeAccent)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(child: Text(value, style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildDriverPerformanceCard(dynamic payroll, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF7ED957).withValues(alpha: 0.1),
            child: Text(payroll.driverName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payroll.driverName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Text('Effective Rate: ${(payroll.effectiveRate * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatSEK(payroll.totalBrutto), style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 15)),
              const Text('REVENUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}