import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/platform_config_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/fleet_api_service.dart';
import 'package:fleetpay/l10n/app_localizations_extension.dart';

class IntegrationSettingsScreen extends ConsumerStatefulWidget {
  const IntegrationSettingsScreen({super.key});

  @override
  ConsumerState<IntegrationSettingsScreen> createState() => _IntegrationSettingsScreenState();
}

class _IntegrationSettingsScreenState extends ConsumerState<IntegrationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  late TextEditingController _fleetIdController;
  bool _obscureSecret = true;
  bool _isSyncing = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clientIdController = TextEditingController();
    _clientSecretController = TextEditingController();
    _fleetIdController = TextEditingController();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _fleetIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(platformConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(platformConfigProvider, (previous, next) {
      next.whenData((config) {
        if (config != null && _clientIdController.text.isEmpty) {
          _clientIdController.text = config.clientId;
          _clientSecretController.text = config.clientSecret;
          _fleetIdController.text = config.fleetId;
        }
      });
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('API INTEGRATION', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: configAsync.when(
        data: (config) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildInfoCard(isDark),
                ),
                const SizedBox(height: 32),
                const Text('BOLT FLEET CREDENTIALS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInputCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _clientIdController,
                        label: 'CLIENT ID',
                        icon: Icons.badge_rounded,
                        hint: 'Enter your Bolt Client ID',
                        isDark: isDark,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _clientSecretController,
                        label: 'CLIENT SECRET',
                        icon: Icons.vpn_key_rounded,
                        hint: 'Enter your Bolt Client Secret',
                        isDark: isDark,
                        obscure: _obscureSecret,
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                          icon: Icon(_obscureSecret ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                const Text('ADDITIONAL CONFIG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInputCard(
                  child: _buildTextField(
                    controller: _fleetIdController,
                    label: 'COMPANY ID (OPTIONAL)',
                    icon: Icons.business_rounded,
                    hint: 'Your Bolt Company/Fleet ID',
                    isDark: isDark,
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                // Date Range Section
                const Text('SYNC DATE RANGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInputCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF7ED957)),
                          SizedBox(width: 8),
                          Text('CHOOSE DATE RANGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(isStart: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7ED957).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF7ED957).withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('FROM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(isStart: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7ED957).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF7ED957).withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Quick presets
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildPresetChip('Last 7d', 7),
                          _buildPresetChip('Last 30d', 30),
                          _buildPresetChip('Last 90d', 90),
                          _buildPresetChip('This Year', 365),
                        ],
                      ),
                    ],
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSyncing ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED957),
                        foregroundColor: Colors.black,
                        elevation: 5,
                        shadowColor: const Color(0xFF7ED957).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isSyncing 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sync_rounded, fontWeight: FontWeight.w900),
                              const SizedBox(width: 12),
                              Text('SAVE & SYNC DATA', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16)),
                            ],
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)] : [const Color(0xFF7ED957), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 28,
            child: Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AUTOMATION ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(
                  'Setup your Bolt credentials to automatically fetch driver trips and earnings.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF7ED957)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final clientId = _clientIdController.text.trim();
    final clientSecret = _clientSecretController.text.trim();
    final fleetId = _fleetIdController.text.trim();

    if (clientId.isEmpty || clientSecret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both Client ID and Secret')));
      return;
    }

    setState(() => _isSyncing = true);

    try {
      // 1. Save credentials to Supabase
      await SupabaseService.saveCredentials(
        clientId: clientId,
        clientSecret: clientSecret,
        fleetId: fleetId.isEmpty ? null : fleetId,
      );

      // 2. Trigger Bolt Sync with the selected date range
      await FleetApiService.syncBoltData(startDate: _startDate, endDate: _endDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Success! Credentials saved and data synced.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync Failed: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildPresetChip(String label, int days) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
      onPressed: () {
        setState(() {
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(Duration(days: days));
        });
      },
      backgroundColor: const Color(0xFF7ED957).withValues(alpha: 0.15),
      side: BorderSide(color: const Color(0xFF7ED957).withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF7ED957),
            onPrimary: Colors.black,
            surface: const Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }
}
