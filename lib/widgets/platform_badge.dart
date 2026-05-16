import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';

class PlatformBadge extends ConsumerWidget {
  final String platformId;
  final bool small;
  
  const PlatformBadge({
    super.key, 
    required this.platformId, 
    this.small = false,
  });

  Color _getColor(String id, Brightness brightness) {
    switch (id) {
      case 'bolt': return const Color(0xFF34A853);
      case 'uber': 
        return brightness == Brightness.dark ? Colors.white70 : Colors.black87;
      case 'wecab': return const Color(0xFF1565C0);
      default: return const Color(0xFF7ED957); // Use primary green for others
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _getColor(platformId, theme.brightness);
    final displayName = platformId[0].toUpperCase() + platformId.substring(1).toLowerCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12, 
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: color, 
          fontSize: small ? 10 : 12, 
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class CommissionBadge extends StatelessWidget {
  final double rate;
  
  const CommissionBadge({super.key, required this.rate});

  Color _getBadgeColor(double rate, ThemeData theme) {
    if (rate >= 0.45) return const Color(0xFF2962FF);
    if (rate >= 0.43) return theme.colorScheme.primary;
    return const Color(0xFF22B14C);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getBadgeColor(rate, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(rate * 100).toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.black, // Dark text on light badge for better readability
          fontSize: 12, 
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}