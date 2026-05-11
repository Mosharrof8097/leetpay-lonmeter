import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import '../models/monthly_payroll.dart';
import '../utils/formatters.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

class PayrollSummaryCard extends StatelessWidget {
  final MonthlyPayroll payroll;
  
  const PayrollSummaryCard({super.key, required this.payroll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_rounded, 
                  color: theme.colorScheme.primary, 
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.get('payroll_specification'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white12),
            _row(l10n.get('provision_incl_semester'), payroll.provisionInklSemester, theme),
            _row(l10n.get('excl_semester'), payroll.exklSemester, theme),
            _row(
              '${l10n.semester} (${(payroll.semesterRate * 100).toStringAsFixed(1)}%)', 
              payroll.semesterAmount, 
              theme,
            ),
            _row('${l10n.fora} 4.5%', payroll.foraAmount, theme),
            _row('${l10n.arbetsgivaravgifter} 31.42%', payroll.arbetsgivaravgifter, theme),
            const Divider(height: 20, color: Colors.white12),
            _row(
              l10n.totalLonekostnad, 
              payroll.totalLonekostnad, 
              theme, 
              bold: true, 
              highlight: true,
            ),
            const SizedBox(height: 12),
            _row(l10n.get('tax_deduction'), -payroll.preliminaryTax, theme, highlight: false),
            _row(
              l10n.get('take_home_pay'), 
              payroll.takeHomePay, 
              theme, 
              bold: true, 
              highlight: true,
            ),
            const Divider(height: 24, color: Colors.white12),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.get('andel_av_inkort'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    formatPercent(payroll.effectiveRate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800, 
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label, 
    double value, 
    ThemeData theme, {
    bool bold = false, 
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label, 
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: highlight ? theme.colorScheme.primary : Colors.grey[300],
              ),
            ),
          ),
          Text(
            formatSEK(value), 
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? theme.colorScheme.primary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}