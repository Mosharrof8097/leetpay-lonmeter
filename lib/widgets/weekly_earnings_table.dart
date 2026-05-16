import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import '../models/earnings_entry.dart';
import '../utils/formatters.dart';
import 'platform_badge.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

class WeeklyEarningsTable extends StatelessWidget {
  final List<EarningsEntry> entries;
  
  const WeeklyEarningsTable({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              l10n.get('no_earnings_registered'),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }

    final sorted = List<EarningsEntry>.from(entries)
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                Icons.table_chart_rounded, 
                size: 20, 
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.weeklyEarnings,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                columnSpacing: 16,
                headingTextStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                columns: [
                  DataColumn(label: Text(l10n.week)),
                  DataColumn(label: Text(l10n.platform)),
                  DataColumn(label: Text(l10n.showBrutto.split(' ').last)),
                  DataColumn(label: Text(l10n.showNetto.split(' ').last)),
                  DataColumn(label: Text(l10n.vat)),
                  DataColumn(label: Text(l10n.tipsTotal.split(' ').first)),
                ],
                rows: sorted.map((e) => DataRow(cells: [
                  DataCell(Text(
                    'V${e.weekNumber}', 
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataCell(PlatformBadge(platformId: e.platformId, small: true)),
                  DataCell(Text(formatNumber(e.bruttoAmount))),
                  DataCell(Text(formatNumber(e.nettoAmount))),
                  DataCell(Text(formatNumber(e.moms6))),
                  DataCell(Text(formatNumber(e.dricks))),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}