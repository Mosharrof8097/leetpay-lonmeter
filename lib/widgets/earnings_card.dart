import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final String? suffix;
  final bool isCurrency;

  const EarningsCard({
    super.key,
    required this.title,
    required this.amount,
    this.icon = Icons.payments_rounded,
    this.color,
    this.subtitle,
    this.suffix,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;
    
    return Card(
      // The borderRadius is handled by CardTheme, but we specify it in BoxDecoration for the gradient overlay
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.1), 
              cardColor.withValues(alpha: 0.02)
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cardColor, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title, 
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            FittedBox(
              child: Text(
                '${isCurrency ? formatSEK(amount) : formatNumber(amount)}${suffix ?? ""}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, 
                  color: cardColor,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!, 
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}