import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/drivers/drivers_screen.dart';
import 'screens/drivers/driver_detail_screen.dart';
import 'screens/drivers/add_driver_screen.dart';
import 'screens/earnings/earnings_screen.dart';
import 'screens/tax_calculator/tax_calculator_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'providers/auth_provider.dart';

import 'screens/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value?.session?.user;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.uri.toString();
      final isAuthRoute = loc == '/login' || loc == '/signup' || loc == '/forgot-password';
      final isSplash = loc == '/';
      
      if (user == null) {
        if (isSplash || isAuthRoute) return null;
        return '/login';
      }

      if (isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/drivers',
            builder: (_, __) => const DriversScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const AddDriverScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => DriverDetailScreen(
                  driverId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/earnings',
            builder: (_, __) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tax-calculator',
        builder: (_, __) => const TaxCalculatorScreen(),
      ),
    ],
  );
});

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  static int _calcIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/dashboard')) return 0;
    if (loc.startsWith('/drivers')) return 1;
    if (loc.startsWith('/earnings')) return 2;
    if (loc.startsWith('/reports')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _calcIndex(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_earning_fab', // Fix: Prevents Hero tag collision crash
        onPressed: () => context.go('/earnings'),
        backgroundColor: theme.colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Creates the beautiful notch
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias, // Ensures smooth rounded corners
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.dashboard_rounded,
              label: l10n.dashboard,
              isSelected: idx == 0,
              onTap: () => context.go('/dashboard'),
            ),
            _buildNavItem(
              context,
              icon: Icons.people_rounded,
              label: l10n.drivers,
              isSelected: idx == 1,
              onTap: () => context.go('/drivers'),
            ),
            const SizedBox(width: 48), // Spacer for the FAB in the notch
            _buildNavItem(
              context,
              icon: Icons.assessment_rounded,
              label: l10n.reports,
              isSelected: idx == 3,
              onTap: () => context.go('/reports'),
            ),
            _buildNavItem(
              context,
              icon: Icons.settings_rounded,
              label: l10n.settings,
              isSelected: idx == 4,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : Colors.grey[500];

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}