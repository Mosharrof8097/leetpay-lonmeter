import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/driver_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../models/driver.dart';
import '../../models/monthly_payroll.dart';
import '../../utils/formatters.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  void _showDriverForm([Driver? driver]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriverForm(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driverProvider);
    final now = DateTime.now();
    final payrolls = ref.watch(monthlyPayrollProvider((month: now.month, year: now.year)));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('MANAGE DRIVERS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.read(driverProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDriverForm(),
        backgroundColor: const Color(0xFF7ED957),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('NEW DRIVER', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(driverProvider.notifier).refresh(),
        child: drivers.isEmpty
          ? Center(
              child: FadeInUp(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_outline_rounded, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('No Drivers Found', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Add your first driver to get started', style: TextStyle(color: Colors.grey)),
                ]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: drivers.length,
              itemBuilder: (context, i) {
                final d = drivers[i];
                final payroll = payrolls.firstWhere((p) => p.driverId == d.id, orElse: () => MonthlyPayroll(driverId: d.id, driverName: d.name, month: now.month, year: now.year));
                return FadeInLeft(
                  delay: Duration(milliseconds: i * 100),
                  child: _PremiumDriverCard(
                    driver: d,
                    payroll: payroll,
                    onEdit: () => _showDriverForm(d),
                    onDelete: () => _confirmDelete(d),
                  ),
                );
              },
            ),
      ),
    );
  }

  void _confirmDelete(Driver d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Driver?'),
        content: Text('Are you sure you want to remove ${d.name}? All history will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(driverProvider.notifier).deleteDriver(d.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _PremiumDriverCard extends StatelessWidget {
  final Driver driver;
  final MonthlyPayroll? payroll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PremiumDriverCard({required this.driver, this.payroll, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBolt = driver.platform == 'Bolt';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/calculation/driver/${driver.id}'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        driver.name[0].toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBolt ? const Color(0xFF7ED957).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isBolt ? Icons.bolt_rounded : Icons.directions_car_rounded,
                                      size: 14,
                                      color: isBolt ? const Color(0xFF2E7D32) : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      driver.platform.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: isBolt ? const Color(0xFF2E7D32) : Colors.grey,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (driver.phone != null && driver.phone!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.phone_rounded, size: 14, color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  driver.phone!,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 26),
                      tooltip: 'Edit Profile',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Delete Driver',
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                // Savings Summary
                Row(
                  children: [
                    Expanded(child: _buildSavingItem('Holiday', driver.totalHolidaySaved, Colors.orangeAccent)),
                    Expanded(child: _buildSavingItem('Pension', driver.totalPensionSaved, Colors.blueAccent)),
                    Expanded(child: _buildSavingItem('Tuition', driver.totalTuitionSaved, Colors.purpleAccent)),
                    if (payroll != null && payroll!.totalBrutto > 0)
                      Expanded(
                        child: _buildSavingItem(
                          'Unsettled Gross', 
                          payroll!.totalBrutto, 
                          const Color(0xFF7ED957),
                        )
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatSEK(amount),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ],
    );
  }
}

class _DriverForm extends ConsumerStatefulWidget {
  final Driver? driver;
  const _DriverForm({this.driver});

  @override
  ConsumerState<_DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends ConsumerState<_DriverForm> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _customPlatformController;
  late String _selectedPlatform;
  bool _isPlatformLocked = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver?.name ?? '');
    _phoneController = TextEditingController(text: widget.driver?.phone ?? '');
    
    final p = widget.driver?.platform ?? 'Bolt';
    if (['Bolt', 'Uber'].contains(p)) {
      _selectedPlatform = p;
      _customPlatformController = TextEditingController();
    } else {
      _selectedPlatform = 'Other';
      _customPlatformController = TextEditingController(text: p);
    }
    
    if (widget.driver == null) _isPlatformLocked = false;
  }

  void _save() {
    if (_nameController.text.isEmpty) return;
    
    final platformToSave = _selectedPlatform == 'Other' 
        ? (_customPlatformController.text.isEmpty ? 'Other' : _customPlatformController.text)
        : _selectedPlatform;

    if (widget.driver == null) {
      final newDriver = Driver(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text,
        commissionRate: 0.43,
        platform: platformToSave,
      );
      ref.read(driverProvider.notifier).addDriver(newDriver);
    } else {
      final updated = widget.driver!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        platform: platformToSave,
      );
      ref.read(driverProvider.notifier).updateDriver(updated);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _customPlatformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.driver == null ? 'ADD NEW DRIVER' : 'EDIT PROFILE',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Driver Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Enter name',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '+46 ...',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Working Platform', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isPlatformLocked ? Colors.transparent : theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPlatform,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: _isPlatformLocked ? Colors.grey : theme.colorScheme.primary),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w900, 
                          color: _isPlatformLocked ? Colors.grey : (isDark ? Colors.white : Colors.black)
                        ),
                        items: ['Bolt', 'Uber', 'Other'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: _isPlatformLocked ? null : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPlatform = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _isPlatformLocked = !_isPlatformLocked),
                  icon: Icon(_isPlatformLocked ? Icons.lock_rounded : Icons.lock_open_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: _isPlatformLocked ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    foregroundColor: _isPlatformLocked ? Colors.orangeAccent : Colors.green,
                  ),
                ),
              ],
            ),
            if (_selectedPlatform == 'Other') ...[
              const SizedBox(height: 20),
              const Text('Custom Platform Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: TextField(
                  controller: _customPlatformController,
                  enabled: !_isPlatformLocked,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'e.g. Foodora, Wecab',
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7ED957),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
