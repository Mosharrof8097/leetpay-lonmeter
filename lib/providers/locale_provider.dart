import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_loadLocale()) {
    Intl.defaultLocale = state.toString();
  }

  static Locale _loadLocale() {
    final code = DatabaseService.getSetting('locale') as String?;
    return Locale(code ?? 'sv');
  }

  void setLocale(Locale locale) {
    state = locale;
    Intl.defaultLocale = locale.toString();
    DatabaseService.saveSetting('locale', locale.languageCode);
  }
}
