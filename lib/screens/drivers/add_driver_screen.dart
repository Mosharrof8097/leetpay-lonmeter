import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/driver_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/driver.dart';
import 'package:fleetpay/l10n/app_localizations.dart';



class AddDriverScreen extends ConsumerStatefulWidget {
  const AddDriverScreen({super.key});

  @override
  ConsumerState<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends ConsumerState<AddDriverScreen> {
  final _nameController = TextEditingController();
  double? _commissionRate;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(

      appBar: AppBar(title: Text(l10n.get('new_driver'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [


            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.get('driver_name'),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? l10n.get('enter_driver_name') : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            Text(
              l10n.get('commission_label'),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [0.37, 0.43, 0.45].map((rate) => ChoiceChip(
                label: Text('${(rate * 100).toStringAsFixed(0)}%'),
                selected: _commissionRate == rate,
                onSelected: (selected) {
                  if (selected) setState(() => _commissionRate = rate);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _commissionRate != null ? (_commissionRate! * 100).toStringAsFixed(1) : '',
              decoration: InputDecoration(
                labelText: '${l10n.get('custom_commission')} (%)',
                prefixIcon: const Icon(Icons.percent_rounded),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final rate = double.tryParse(v);
                if (rate != null) setState(() => _commissionRate = rate / 100);
              },
            ),


            const SizedBox(height: 40),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(l10n.get('save_driver')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_commissionRate == null) return;
    
    final l10n = AppLocalizations.of(context)!;
    final newDriver = Driver(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      commissionRate: _commissionRate!,
    );
    ref.read(driverProvider.notifier).addDriver(newDriver);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.get('driver_added')), behavior: SnackBarBehavior.floating),
    );
  }
}