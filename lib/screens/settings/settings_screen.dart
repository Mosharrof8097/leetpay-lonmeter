import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/driver_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import '../../widgets/import_dialogs.dart';
import '../../services/file_import_service.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../import_history/import_history_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../providers/platform_config_provider.dart';



class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _companyController;
  late FocusNode _companyFocusNode;
  late int _taxYear;
  late double _defaultRate;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _companyController =
        TextEditingController(text: DatabaseService.getCompanyName());
    _companyFocusNode = FocusNode();
    _taxYear = DatabaseService.getTaxYear();
    _defaultRate = DatabaseService.getDefaultCommissionRate();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }

  bool _isSavingCompany = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final companyName = ref.watch(companyNameProvider);


    // Use ref.listen to react to changes from the backend without interrupting typing
    ref.listen<String>(companyNameProvider, (prev, next) {
      if (!_companyFocusNode.hasFocus && !_isSavingCompany) {
        _companyController.text = next;
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Company section
          _SectionHeader(
            icon: Icons.business_rounded,
            title: l10n.company,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(
                  controller: _companyController,
                  focusNode: _companyFocusNode,
                  decoration: InputDecoration(
                    labelText: l10n.companyName,
                    prefixIcon: const Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingCompany ? null : () async {
                      setState(() => _isSavingCompany = true);
                      FocusScope.of(context).unfocus();
                      try {
                        await ref.read(companyNameProvider.notifier).updateName(_companyController.text.trim());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.companyNameUpdated),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF34A853),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.syncError),
                              content: Text('${l10n.syncErrorDesc}\n\n${l10n.errorMessage(e.toString())}'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(l10n.ok),
                                ),
                              ],
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSavingCompany = false);
                      }
                    },
                    icon: _isSavingCompany 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                    label: Text(_isSavingCompany ? l10n.saving : l10n.saveCompanyName),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  value: _taxYear,
                  decoration: InputDecoration(labelText: l10n.taxYear),
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                      .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _taxYear = v!);
                    DatabaseService.saveSetting('taxYear', v);
                  },
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),


          // Language section
          _SectionHeader(
            icon: Icons.language_rounded,
            title: 'Language / Språk',
          ),
          Card(
            child: Column(children: [
              RadioListTile<Locale>(
                title: const Text('Svenska'),
                value: const Locale('sv'),
                groupValue: ref.watch(localeProvider),
                onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
              ),
              RadioListTile<Locale>(
                title: const Text('English'),
                value: const Locale('en'),
                groupValue: ref.watch(localeProvider),
                onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Theme section
          _SectionHeader(
            icon: Icons.palette_rounded,
            title: l10n.appearance,
          ),
          Card(
            child: Column(children: [
              RadioListTile<ThemeMode>(
                title: Text(l10n.systemStandard),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.lightMode),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.darkMode),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Backup & Restore
          _SectionHeader(
            icon: Icons.cloud_sync_rounded,
            title: l10n.backupRestore,
          ),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Color(0xFF2962FF)),
                title: Text(l10n.exportJson),
                subtitle: Text(l10n.saveAsJson),
                onTap: _exportJSON,
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.upload_rounded, color: Color(0xFF2962FF)),
                title: Text(l10n.importJson),
                subtitle: Text(l10n.restoreFromJson),
                onTap: _importJSON,
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // SaaS Integrations
          _SectionHeader(
            icon: Icons.hub_rounded,
            title: l10n.saasIntegrations,
          ),
          Card(
            child: Column(children: [
              Consumer(
                builder: (context, ref, child) {
                  final configAsync = ref.watch(platformConfigProvider);
                  return configAsync.when(
                    data: (config) {
                      debugPrint('SettingsScreen: UI received config: ${config?.clientId}');
                      return ListTile(
                        leading: Icon(
                          Icons.bolt_rounded, 
                          color: config != null ? const Color(0xFF7ED957) : Colors.amber
                        ),
                        title: Text(l10n.boltFleetApi),
                        subtitle: Text(config != null ? l10n.connected : l10n.setupCredentials),
                        trailing: config != null 
                          ? const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF7ED957))
                          : const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings/integration'),
                      );
                    },
                    loading: () => ListTile(
                      leading: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text(l10n.boltFleetApi),
                      subtitle: Text(l10n.checkingConnection),
                    ),
                    error: (err, _) => ListTile(
                      leading: const Icon(Icons.error_outline_rounded, color: Colors.red),
                      title: Text(l10n.boltFleetApi),
                      subtitle: Text('${l10n.errorMessage(err.toString())}'),
                      onTap: () => context.push('/settings/integration'),
                    ),
                  );
                },
              ),
            ]),
          ),
          const SizedBox(height: 24),


          // Data management
          _SectionHeader(
            icon: Icons.storage_rounded,
            title: l10n.dataManagement,
          ),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.table_chart_rounded, color: Color(0xFF34A853)),
                title: Text(l10n.importData),
                subtitle: Text(l10n.universalImporter),
                onTap: _importData,
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Color(0xFF7ED957)),
                title: Text(l10n.importHistory),
                subtitle: Text(l10n.viewRevertHistory),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportHistoryScreen())),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: Text(l10n.get('delete_all_data'), style: const TextStyle(color: Colors.red)),
                onTap: _clearData,
              ),
            ]),
          ),


          // Logout section
          _SectionHeader(
            icon: Icons.logout_rounded,
            title: l10n.account,
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.orangeAccent),
              title: Text(l10n.logout),
              subtitle: Text(l10n.signOutDesc),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                await DatabaseService.clearAllData();
                // Redirection is handled by the router
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    const platformId = 'manual';
    bool loadingShown = false;

    try {
      // 1. Pick File
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result == null || result.files.single.path == null || !mounted) return;
      final filePath = result.files.single.path!;

      // 2. Get Headers & Map
      final headers = await FileImportService.getHeaders(filePath);
      if (headers == null || !mounted) return;

      final mapping = await showDialog<ColumnMapping>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AutoMappingDialog(headers: headers, platformId: platformId),
      );

      if (mapping == null || !mounted) return;

      // 3. Preview Data
      final previewData = await FileImportService.getPreviewData(filePath, mapping);
      if (previewData.isEmpty || !mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => ImportPreviewDialog(
          previewData: previewData,
          fileName: result.files.single.name,
        ),
      );

      if (confirm != true || !mounted) return;

      // 4. Process with Progress
      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      final count = await FileImportService.processImport(
        filePath: filePath,
        platformId: platformId,
        mapping: mapping,
        onNameMismatch: (name) async {
          if (!mounted) return null;
          return await showDialog<String>(
            context: context,
            useRootNavigator: true,
            builder: (ctx) => NameMismatchDialog(unmatchedName: name),
          );
        },
      );

      if (!context.mounted) return;
      
      // 5. Refresh data & Invalidate Payroll AFTER success
      await ref.read(driverProvider.notifier).refresh();
      await ref.read(earningsProvider.notifier).refresh();
      ref.invalidate(monthlyPayrollProvider);

      if (loadingShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });
        loadingShown = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importData),
            content: Text(l10n.importComplete(count)),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.ok))],
          ),
        );
      });
    } catch (e) {
      debugPrint('Import crash prevented: $e');
      
      if (loadingShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });
        loadingShown = false;
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importData),
            content: Text(l10n.importFailed(e.toString())),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.ok))],
          ),
        );
      });
    }
  }


  Future<void> _exportJSON() async {
    try {
      final data = await DatabaseService.exportBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/lonmeter_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], subject: 'Lönmeter JSON Backup');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(e.toString()))));
    }
  }

  Future<void> _importJSON() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
      
      try {
        final content = await File(result.files.single.path!).readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        await DatabaseService.importAllData(data);
        
        if (mounted) {
          Navigator.of(context).pop(); // Pop loading
          ref.read(driverProvider.notifier).refresh();
          ref.read(earningsProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(

            content: Text('Backup restored successfully!'),
            backgroundColor: Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }



  void _clearData() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.deleteAllContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              await DatabaseService.clearAllData();
              ref.read(driverProvider.notifier).refresh();
              ref.read(earningsProvider.notifier).refresh();

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dataErased), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]),
    );
  }
}