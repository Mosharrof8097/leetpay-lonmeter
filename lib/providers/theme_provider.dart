import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadThemeMode());

  static ThemeMode _loadThemeMode() {
    final mode = DatabaseService.getSetting('themeMode') as String?;
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    String modeString;
    switch (mode) {
      case ThemeMode.light: modeString = 'light'; break;
      case ThemeMode.dark: modeString = 'dark'; break;
      case ThemeMode.system: modeString = 'system'; break;
    }
    DatabaseService.saveSetting('themeMode', modeString);
  }
}
