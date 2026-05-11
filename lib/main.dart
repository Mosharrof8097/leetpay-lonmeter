import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'router.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseService.init();
  await DatabaseService.init();

  try {
    await NotificationService.init();
    await NotificationService.scheduleWeeklyReminder();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  runApp(const ProviderScope(child: LonmeterApp()));
}

class LonmeterApp extends ConsumerWidget {
  const LonmeterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Lönmeter',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Core Palette - Dark (Preserved)
    const primaryNeonGreen = Color(0xFF7ED957);
    const darkScaffold = Color(0xFF0A0A0A);
    const darkSurface = Color(0xFF1E1E1E);
    const darkSecondaryText = Color(0xFF9E9E9E);

    // Core Palette - Light (New)
    const lightScaffold = Color(0xFFF8F9FA);
    const lightSurface = Colors.white;
    const lightText = Color(0xFF1A1C1E);
    const lightSecondaryText = Color(0xFF6C757D);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryNeonGreen,
      brightness: brightness,
      primary: primaryNeonGreen,
      onPrimary: Colors.black,
      surface: isDark ? darkSurface : lightSurface,
      onSurface: isDark ? Colors.white : lightText,
      error: Colors.redAccent,
    );

    final scaffoldBackground = isDark ? darkScaffold : lightScaffold;
    final secondaryText = isDark ? darkSecondaryText : lightSecondaryText;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 4 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeonGreen,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        labelStyle: TextStyle(color: secondaryText),
        hintStyle: TextStyle(color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNeonGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        indicatorColor: primaryNeonGreen.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primaryNeonGreen, fontWeight: FontWeight.bold);
          }
          return TextStyle(color: secondaryText);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryNeonGreen);
          }
          return IconThemeData(color: secondaryText);
        }),
      ),
    );
  }
}