import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/driver_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../models/driver.dart';
import '../../utils/formatters.dart';
import '../../services/supabase_service.dart';
import '../../services/fleet_api_service.dart';
import '../../providers/dashboard_provider.dart';
import '../dashboard/widgets/dashboard_widgets.dart';

class CalculationScreen extends ConsumerStatefulWidget {
  const CalculationScreen({super.key});

  @override
  ConsumerState<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends ConsumerState<CalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Input Controllers
  final _grossController = TextEditingController();
  final _tipsController = TextEditingController();
  final _platformNameController = TextEditingController();
  
  // State variables
  String _selectedPlatform = 'Bolt';
  String? _selectedDriverId;
  double _govtTaxPercent = 5.66;
  double _platformFeePercent = 20.0;
  double _holidayPayPercent = 12.0;
  double _tuitionFeePercent = 0.0;
  double _pensionPercent = 4.5;
  double _driverSharePercent = 43.0;
  
  bool _isGovtTaxLocked = true;
  bool _isSyncing = false;
  bool _isLoadingData = false;

  @override
  void dispose() {
    _grossController.dispose();
    _tipsController.dispose();
    _platformNameController.dispose();
    super.dispose();
  }

  double get _gross => double.tryParse(_grossController.text) ?? 0.0;
  double get _tips => double.tryParse(_tipsController.text) ?? 0.0;
  
  // Step 1: Mandatory deductions from GROSS
  double get _taxAmount => _gross * (_govtTaxPercent / 100);
  double get _feeAmount => _gross * (_platformFeePercent / 100);
  
  // Step 2: What's left to split between company and driver
  double get _splitPot => _gross - _taxAmount - _feeAmount;
  
  // Step 3: Split between company and driver
  double get _totalDriverAllocation => _splitPot * (_driverSharePercent / 100);
  double get _companyProfit => _splitPot - _totalDriverAllocation;
  
  // Step 4: Benefits calculated FROM DRIVER'S ALLOCATION (not from split pot!)
  // Swedish law: holiday pay, pension, tuition are based on driver's salary
  double get _holidayAmount => _totalDriverAllocation * (_holidayPayPercent / 100);
  double get _tuitionAmount => _totalDriverAllocation * (_tuitionFeePercent / 100);
  double get _pensionAmount => _totalDriverAllocation * (_pensionPercent / 100);
  
  // Step 5: Driver's actual cash in hand after benefits are set aside
  double get _driverBasicPay => _totalDriverAllocation - _holidayAmount - _tuitionAmount - _pensionAmount;

  void _onPlatformChanged(String? p) {
    if (p == null) return;
    setState(() {
      _selectedPlatform = p;
      if (p == 'Bolt') {
        _platformFeePercent = 20.0;
        _govtTaxPercent = 5.66;
      } else if (p == 'Uber') {
        _platformFeePercent = 25.0;
        _govtTaxPercent = 5.66;
      }
    });
  }

  void _onDriverChanged(String? driverId) {
    if (driverId == null) return;
    final drivers = ref.read(driverProvider);
    final d = drivers.firstWhere((dr) => dr.id == driverId);
    setState(() {
      _selectedDriverId = driverId;
      _driverSharePercent = (d.commissionRate).toDouble() * 100;
    });
    _fetchUnsettledDataForDriver(driverId);
  }

  Future<void> _fetchUnsettledDataForDriver(String driverId) async {
    setState(() => _isLoadingData = true);
    try {
      final earnings = ref.read(rawEarningsProvider).value ?? [];
      
      double gross = 0;
      double tips = 0;
      
      for (var e in earnings) {
        if (e['driver_id'] == driverId || e['driver_uuid'] == driverId) {
          gross += (e['brutto_amount'] as num? ?? 0).toDouble();
          tips += (e['dricks'] as num? ?? 0).toDouble();
        }
      }
      
      setState(() {
        _grossController.text = gross > 0 ? gross.toStringAsFixed(2) : '';
        _tipsController.text = tips > 0 ? tips.toStringAsFixed(2) : '';
        // Netto logic is handled by the waterfall card using gross and percentages
      });
    } catch (e) {
      // If no data found, just clear or leave as is
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driverProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('CALCULATOR', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 12, 16, size.height * 0.1),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSetupCard(drivers, theme),
              const SizedBox(height: 16),
              _buildRevenueInputs(theme, isDark),
              const SizedBox(height: 16),
              _buildDeductionCard(theme, isDark),
              // 4. Final Receipt Breakdown
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: RevenueWaterfallCard(
                  gross: _gross,
                  tax: _taxAmount,
                  fees: _feeAmount,
                  net: _splitPot,
                  tips: _tips,
                  driverPay: _driverBasicPay,
                  companyProfit: _companyProfit,
                  holidayPay: _holidayAmount,
                  pension: _pensionAmount,
                  tuition: _tuitionAmount,
                  driverName: drivers.any((d) => d.id == _selectedDriverId) ? drivers.firstWhere((d) => d.id == _selectedDriverId).name : null,
                ),
              ),
              const SizedBox(height: 32),
              _buildSaveButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupCard(List<Driver> drivers, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedPlatform,
            isExpanded: true,
            decoration: _inputDecoration('Platform', Icons.layers_rounded, theme),
            items: ['Bolt', 'Uber', 'Other'].map((p) => DropdownMenuItem<String>(
              value: p,
              child: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
            )).toList(),
            onChanged: _onPlatformChanged,
          ),
          if (_selectedPlatform == 'Other') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _platformNameController,
              decoration: _inputDecoration('Platform Name', Icons.edit_note_rounded, theme),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: drivers.any((d) => d.id == _selectedDriverId) ? _selectedDriverId : null,
            isExpanded: true,
            decoration: _inputDecoration('Driver', Icons.person_rounded, theme),
            items: drivers.map((d) => DropdownMenuItem<String>(
              value: d.id,
              child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: _onDriverChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueInputs(ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildRevenueField(
          controller: _grossController,
          label: 'GROSS REVENUE',
          icon: Icons.account_balance_wallet_rounded,
          color: theme.colorScheme.primary,
          showSync: _selectedPlatform == 'Bolt',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildRevenueField(
          controller: _tipsController,
          label: 'TIPS (TAX-FREE)',
          icon: Icons.volunteer_activism_rounded,
          color: Colors.orangeAccent,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildRevenueField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool showSync = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(suffixText: 'SEK', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
          if (showSync) 
            _isSyncing 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton.filled(
                  onPressed: _syncWithBolt,
                  icon: const Icon(Icons.bolt_rounded, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.1),
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDeductionCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildConfigHeader('DEDUCTION SETTINGS (%)'),
          const SizedBox(height: 16),
          
          // Govt Tax with Lock
          _buildConfigRow(
            'Govt Tax', 
            _govtTaxPercent, 
            (v) => setState(() => _govtTaxPercent = v), 
            Colors.redAccent,
            isLocked: _isGovtTaxLocked,
            onLockToggle: () => setState(() => _isGovtTaxLocked = !_isGovtTaxLocked),
          ),
          
          const SizedBox(height: 12),
          _buildConfigRow('Platform Fee', _platformFeePercent, (v) => setState(() => _platformFeePercent = v), Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildConfigRow('Holiday Pay', _holidayPayPercent, (v) => setState(() => _holidayPayPercent = v), Colors.blueAccent),
          const SizedBox(height: 12),
          _buildConfigRow('Tuition Fee', _tuitionFeePercent, (v) => setState(() => _tuitionFeePercent = v), Colors.purpleAccent),
          const SizedBox(height: 12),
          _buildConfigRow('Pension (Fora)', _pensionPercent, (v) => setState(() => _pensionPercent = v), Colors.greenAccent),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          
          _buildConfigHeader('PAYOUT SHARING (%)'),
          const SizedBox(height: 16),
          _buildConfigRow('Driver Share', _driverSharePercent, (v) => setState(() => _driverSharePercent = v), const Color(0xFF7ED957)),
        ],
      ),
    );
  }

  Widget _buildConfigHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF7ED957), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey)),
      ],
    );
  }

  Widget _buildConfigRow(
    String label, 
    double value, 
    Function(double) onChanged, 
    Color accent, 
    {bool? isLocked, VoidCallback? onLockToggle}
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey)),
              if (onLockToggle != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onLockToggle,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isLocked! ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 14,
                      color: isLocked ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 90,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLocked == true 
              ? (isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05))
              : (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLocked == true ? Colors.transparent : accent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('${label}_${isLocked}_$value'),
                  initialValue: value.toString(),
                  enabled: isLocked != true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900, 
                    fontSize: 14, 
                    color: isLocked == true ? Colors.grey : (isDark ? Colors.white : Colors.black87)
                  ),
                  onChanged: (v) => onChanged(double.tryParse(v) ?? 0.0),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(width: 4),
              const Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveCalculation,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('SAVE TO LEDGER', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Future<void> _syncWithBolt() async {
    setState(() => _isSyncing = true);
    try {
      await FleetApiService.syncBoltData();
      await ref.read(driverProvider.notifier).refresh();
      if (_selectedDriverId != null) {
        await _fetchUnsettledDataForDriver(_selectedDriverId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ Bolt Data Synced Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _saveCalculation() {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a driver'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => FadeInScale(
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF7ED957)),
              const SizedBox(width: 12),
              Text('Confirm Entry', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow('Driver', ref.read(driverProvider).firstWhere((d) => d.id == _selectedDriverId, orElse: () => Driver(id: '', name: 'Unknown', commissionRate: 0.43)).name, isBold: true),
              _buildDialogRow('Platform', _selectedPlatform == 'Other' ? _platformNameController.text : _selectedPlatform),
              const Divider(height: 24),
              _buildDialogRow('Split Pot (Net)', formatSEK(_splitPot)),
              _buildDialogRow('Company Profit', formatSEK(_companyProfit), color: Colors.purpleAccent),
              _buildDialogRow('Driver Allocation', formatSEK(_totalDriverAllocation), color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(
                '* Driver will receive ${formatSEK(_driverBasicPay)} cash + benefits + tips',
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performFinalSave();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ED957),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CONFIRM & SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performFinalSave() async {
    if (_selectedDriverId == null) return;

    try {
      final now = DateTime.now();
      final payrolls = ref.read(monthlyPayrollProvider((month: now.month, year: now.year)));
      final payroll = payrolls.firstWhere((p) => p.driverId == _selectedDriverId);

      await SupabaseService.saveSettlement(payroll);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved settlement for ${ref.read(driverProvider).firstWhere((d) => d.id == _selectedDriverId, orElse: () => Driver(id: '', name: 'Unknown Driver', commissionRate: 0.43)).name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'VIEW REPORTS', textColor: Colors.white, onPressed: () => context.go('/reports')),
          ),
        );
        // Refresh data
        ref.invalidate(unsettledEarningsProvider);
        setState(() {
          _grossController.clear();
          _tipsController.clear();
          _selectedDriverId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildDialogRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInScale extends StatefulWidget {
  final Widget child;
  const FadeInScale({super.key, required this.child});

  @override
  State<FadeInScale> createState() => _FadeInScaleState();
}

class _FadeInScaleState extends State<FadeInScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fadeAnimation, child: ScaleTransition(scale: _scaleAnimation, child: widget.child));
  }
}
