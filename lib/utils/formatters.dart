import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

/// Format a number as currency based on locale
String formatSEK(double amount) {
  final formatter = NumberFormat.currency(
    symbol: 'kr',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format a number as percentage
String formatPercent(double rate) {
  return '${(rate * 100).toStringAsFixed(1)}%';
}

/// Format a number with thousands separators based on locale
String formatNumber(double value) {
  return NumberFormat('#,##0').format(value);
}

/// Get month name using AppLocalizations
String getLocalizedMonthName(BuildContext context, int month) {
  return AppLocalizations.of(context)!.getMonthName(month);
}

/// Swedish month name helper (non-context version for services)
String getSwedishMonthName(int month) {
  const months = [
    '', 'Januari', 'Februari', 'Mars', 'April', 'Maj', 'Juni',
    'Juli', 'Augusti', 'September', 'Oktober', 'November', 'December'
  ];
  if (month < 1 || month > 12) return '';
  return months[month];
}

/// Format week number
String formatWeek(BuildContext context, int week) {
  final l10n = AppLocalizations.of(context)!;
  return '${l10n.week} $week';
}

/// Parse a double from text, handling both comma and dot as decimal separator
double parseSwedishDouble(String text) {
  if (text.isEmpty) return 0.0;
  final cleaned = text.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0.0;
}

/// Parse a double from text (generic)
double parseDouble(String text) {
  if (text.isEmpty) return 0.0;
  final cleaned = text.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0.0;
}