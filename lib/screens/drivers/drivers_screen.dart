import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/platform_badge.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import '../../models/driver.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  Future<void> _deleteDriver(Driver driver) async {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDriverTitle),
        content: Text(l10n.get('delete_driver_content').replaceAll('{name}', driver.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // 2. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // 3. Perform deletion
      await ref.read(driverProvider.notifier).deleteDriver(driver.id);
      
      // Explicitly invalidate providers to force dashboard refresh
      ref.invalidate(monthlyPayrollProvider);
      ref.invalidate(earningsProvider);
      
      // 4. Handle success
      if (!mounted) return;
      
      // Close the loading dialog using the root navigator
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.name} ${l10n.delete.toLowerCase()}d'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // 5. Handle error
      if (!mounted) return;
      
      // Close the loading dialog using the root navigator
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('errorMessage').replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driverProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drivers),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(driverProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/drivers/add'),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l10n.newDriver),
      ),
      body: drivers.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(l10n.noDrivers, style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(l10n.addFirstDriver, style: TextStyle(color: Colors.grey[500])),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: drivers.length,
              itemBuilder: (context, i) {
                final d = drivers[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => context.push('/drivers/${d.id}'),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: d.isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      child: Text(
                        d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: d.isActive ? theme.colorScheme.primary : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      d.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: d.isActive ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: d.isActive ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            d.isActive ? l10n.active : l10n.inactive,
                            style: TextStyle(
                              color: d.isActive ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CommissionBadge(rate: d.commissionRate),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _deleteDriver(d),
                          tooltip: l10n.delete,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
