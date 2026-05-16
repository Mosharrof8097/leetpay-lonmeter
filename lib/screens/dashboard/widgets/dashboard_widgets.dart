import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/formatters.dart';

class RevenueWaterfallCard extends StatelessWidget {
  final double gross;
  final double tax;
  final double fees;
  final double net;
  final double? tips;
  final double? driverPay;
  final double? companyProfit;
  final double? holidayPay;
  final double? pension;
  final double? tuition;
  final String? driverName;
  final DateTimeRange? dateRange;

  const RevenueWaterfallCard({
    super.key,
    required this.gross,
    required this.tax,
    required this.fees,
    required this.net,
    this.tips,
    this.driverPay,
    this.companyProfit,
    this.holidayPay,
    this.pension,
    this.tuition,
    this.driverName,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSummaryMode = driverPay == null;
    
    final totalDriverPayout = (driverPay ?? 0) + 
                             (holidayPay ?? 0) + 
                             (pension ?? 0) + 
                             (tuition ?? 0) + 
                             (tips ?? 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSummaryMode ? 'Revenue Breakdown' : (driverName ?? 'Calculation'),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      dateRange != null 
                        ? '${DateFormat('MMM dd').format(dateRange!.start)} — ${DateFormat('MMM dd, yyyy').format(dateRange!.end)}'
                        : DateFormat('MMM dd, yyyy | HH:mm').format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSummaryMode ? Icons.analytics_rounded : Icons.receipt_long_rounded, 
                  color: theme.colorScheme.primary
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRow(theme, 'Gross Revenue', gross, theme.colorScheme.primary, isBold: true, icon: Icons.account_balance_rounded),
          const SizedBox(height: 16),
          _buildSectionHeader('DEDUCTIONS'),
          _buildRow(theme, 'Govt Tax', -tax, Colors.redAccent, icon: Icons.gavel_rounded),
          _buildRow(theme, 'Platform Fees', -fees, Colors.orangeAccent, icon: Icons.hub_rounded),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
          
          if (isSummaryMode) ...[
            _buildSectionHeader('NET TOTAL'),
            _buildRow(theme, 'Net Profit/Revenue', net, const Color(0xFF7ED957), isBold: true, icon: Icons.monetization_on_rounded),
          ] else ...[
            _buildSectionHeader('PAYOUT BREAKDOWN'),
            if (driverPay != null) _buildRow(theme, 'Basic Share', driverPay!, Colors.blueAccent, icon: Icons.person_outline_rounded),
            if (holidayPay != null && holidayPay! > 0) _buildRow(theme, 'Holiday Pay', holidayPay!, Colors.teal, icon: Icons.beach_access_rounded),
            if (pension != null && pension! > 0) _buildRow(theme, 'Pension (Fora)', pension!, Colors.teal, icon: Icons.savings_rounded),
            if (tuition != null && tuition! > 0) _buildRow(theme, 'Tuition Fee', tuition!, Colors.teal, icon: Icons.school_rounded),
            if (tips != null && tips! > 0) _buildRow(theme, 'Tips (Tax-Free)', tips!, Colors.teal, icon: Icons.volunteer_activism_rounded),
            const SizedBox(height: 12),
            if (companyProfit != null) _buildRow(theme, 'Company Net Profit', companyProfit!, Colors.purpleAccent, icon: Icons.business_center_rounded, isBold: true),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Driver Total Payout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF00C853))),
                  Text(formatSEK(totalDriverPayout), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF00C853))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
    );
  }

  Widget _buildRow(ThemeData theme, String label, double value, Color color, {bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color.withValues(alpha: 0.6)), const SizedBox(width: 12)],
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
          Text(formatSEK(value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class NetProfitCard extends StatelessWidget {
  final double amount;
  const NetProfitCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF7ED957), const Color(0xFF7ED957).withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF7ED957).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NET REVENUE', style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.trending_up_rounded, color: Colors.black, size: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text(formatSEK(amount), style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'Montserrat')),
          const SizedBox(height: 4),
          Text('Keep up the great work!', style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PlatformSummaryCard extends StatelessWidget {
  final String platformId;
  final double gross;
  const PlatformSummaryCard({super.key, required this.platformId, required this.gross});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(platformId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(formatSEK(gross), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class DriverMonitorCard extends StatelessWidget {
  final String name;
  final double gross;
  final bool isActive;
  const DriverMonitorCard({super.key, required this.name, required this.gross, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer, child: Text(name[0], style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.surface, width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(formatSEK(gross), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7ED957))),
        ],
      ),
    );
  }
}
