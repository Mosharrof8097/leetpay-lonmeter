import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/driver_provider.dart';
import '../../providers/settings_provider.dart';
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
    final commissionRates = ref.watch(commissionRatesProvider);
    
    if (_commissionRate == null && commissionRates.isNotEmpty) {
      _commissionRate = commissionRates.contains(0.43) ? 0.43 : commissionRates.first;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('new_driver'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded, size: 48, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 32),

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
              children: commissionRates.map((rate) => ChoiceChip(
                label: Text('${(rate * 100).toStringAsFixed(1)}%'),
                selected: _commissionRate == rate,
                onSelected: (selected) {
                  if (selected) setState(() => _commissionRate = rate);
                },
              )).toList(),
            ),

            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF2962FF).withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF2962FF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This rate will be used for all tax and commission calculations for this driver.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2962FF)),
                    ),
                  ),
                ]),
              ),
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
    ref.read(driverProvider.notifier).addDriver(
      _nameController.text.trim(), 
      _commissionRate!,
    );
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.get('driver_added')), behavior: SnackBarBehavior.floating),
    );
  }
}