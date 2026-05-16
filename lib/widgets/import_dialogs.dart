import 'package:flutter/material.dart';
import '../models/mapping_preset.dart';
import '../services/file_import_service.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../models/driver.dart';
import 'package:uuid/uuid.dart';
import 'package:fleetpay/l10n/app_localizations.dart';
import 'package:fleetpay/l10n/app_localizations_extension.dart';

class AutoMappingDialog extends StatefulWidget {
  final List<String> headers;
  final String platformId;

  const AutoMappingDialog({super.key, required this.headers, required this.platformId});

  @override
  State<AutoMappingDialog> createState() => _AutoMappingDialogState();
}

class _AutoMappingDialogState extends State<AutoMappingDialog> {
  final _mapping = ColumnMapping();
  List<MappingPreset> _presets = [];
  MappingPreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _initializeMapping();
  }

  void _loadPresets() {
    _presets = DatabaseService.getMappingPresets().where((p) => p.platformId == widget.platformId).toList();
  }

  void _initializeMapping() {
    // Try to guess based on keywords if no preset is selected
    if (_mapping.driverNameIdx == -1) {
      _mapping.driverNameIdx = FileImportService.findBestColumnMatch(widget.headers, ['Driver Name', 'driver', 'name', 'förare', 'namn', 'alias', 'förarnamn']);
    }
    if (_mapping.bruttoIdx == -1) {
      _mapping.bruttoIdx = FileImportService.findBestColumnMatch(widget.headers, ['Brutto Amount', 'brutto', 'amount', 'inkört', 'belopp', 'total', 'revenue', 'gross', 'intäkt', 'earnings']);
    }
    if (_mapping.nettoIdx == -1) {
      _mapping.nettoIdx = FileImportService.findBestColumnMatch(widget.headers, ['Netto Amount', 'netto', 'earnings', 'net', 'payout', 'to pay', 'utbetalning']);
    }
    if (_mapping.weekIdx == -1) {
      _mapping.weekIdx = FileImportService.findBestColumnMatch(widget.headers, ['Week', 'week', 'vecka', 'wk', 'v.']);
    }
    if (_mapping.dricksIdx == -1) {
      _mapping.dricksIdx = FileImportService.findBestColumnMatch(widget.headers, ['Tips', 'tips', 'dricks', 'gratuity']);
    }
    if (_mapping.dateIdx == -1) {
      _mapping.dateIdx = FileImportService.findBestColumnMatch(widget.headers, ['Date', 'date', 'datum', 'tid', 'time', 'period']);
    }
    if (_mapping.feeIdx == -1) {
      _mapping.feeIdx = FileImportService.findBestColumnMatch(widget.headers, ['Fee', 'avgift', 'service fee', 'commission']);
    }
    if (_mapping.referenceIdx == -1) {
      _mapping.referenceIdx = FileImportService.findBestColumnMatch(widget.headers, ['Reference', 'ref', 'order id', 'trip id', 'id']);
    }
  }

  void _applyPreset(MappingPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _mapping.driverNameIdx = preset.mapping['driverNameIdx'] ?? -1;
      _mapping.bruttoIdx = preset.mapping['bruttoIdx'] ?? -1;
      _mapping.nettoIdx = preset.mapping['nettoIdx'] ?? -1;
      _mapping.weekIdx = preset.mapping['weekIdx'] ?? -1;
      _mapping.dricksIdx = preset.mapping['dricksIdx'] ?? -1;
      _mapping.dateIdx = preset.mapping['dateIdx'] ?? -1;
      _mapping.feeIdx = preset.mapping['feeIdx'] ?? -1;
      _mapping.referenceIdx = preset.mapping['referenceIdx'] ?? -1;
    });
  }

  Future<void> _saveAsPreset() async {
    final nameController = TextEditingController();
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.savePreset),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l10n.presetName, hintText: 'e.g., Standard Uber'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, nameController.text), child: Text(l10n.add)),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final preset = MappingPreset(
        id: const Uuid().v4(),
        name: name,
        mapping: _mapping.toMap(),
        platformId: widget.platformId,
      );
      await DatabaseService.saveMappingPreset(preset);
      // Also try to save to Supabase if possible
      try {
        await SupabaseService.saveMappingPreset(preset);
      } catch (e) {
        debugPrint('Failed to sync preset to Supabase: $e');
      }
      setState(() {
        _loadPresets();
        _selectedPreset = preset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.map_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.columnMapping, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_presets.isNotEmpty) ...[
                DropdownButtonFormField<MappingPreset>(
                  value: _selectedPreset,
                  decoration: InputDecoration(
                    labelText: l10n.loadPreset,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.history),
                  ),
                  items: _presets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (v) => _applyPreset(v!),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
              ],
              _buildDropdown(l10n.drivers, _mapping.driverNameIdx, (v) => setState(() => _mapping.driverNameIdx = v!)),
              _buildDropdown(l10n.totalRevenue, _mapping.bruttoIdx, (v) => setState(() => _mapping.bruttoIdx = v!)),
              _buildDropdown('${l10n.showNetto} (Optional)', _mapping.nettoIdx, (v) => setState(() => _mapping.nettoIdx = v!)),
              _buildDropdown(l10n.date, _mapping.dateIdx, (v) => setState(() => _mapping.dateIdx = v!)),
              _buildDropdown('${l10n.week} (Backup)', _mapping.weekIdx, (v) => setState(() => _mapping.weekIdx = v!)),
              _buildDropdown('${l10n.platform} (Optional)', _mapping.feeIdx, (v) => setState(() => _mapping.feeIdx = v!)),
              _buildDropdown('${l10n.tipsTotal} (Optional)', _mapping.dricksIdx, (v) => setState(() => _mapping.dricksIdx = v!)),
              _buildDropdown('${l10n.status} (Optional)', _mapping.referenceIdx, (v) => setState(() => _mapping.referenceIdx = v!)),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(onPressed: _saveAsPreset, child: Text(l10n.savePreset)),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: _mapping.isValid ? () => Navigator.of(context).pop(_mapping) : null,
              child: Text(l10n.preview),
            ),
          ],
        ),
      ],
      actionsPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildDropdown(String label, int current, ValueChanged<int?> onChanged) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<int>(
        value: (current >= -1 && current < widget.headers.length) ? current : -1,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true,
        items: [
          DropdownMenuItem(value: -1, child: Text(l10n.notMapped)),
          ...List.generate(widget.headers.length, (i) {
            final header = widget.headers[i];
            return DropdownMenuItem(
              value: i, 
              child: Text(header.isEmpty ? 'Column $i' : header, overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class ImportPreviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> previewData;
  final String fileName;

  const ImportPreviewDialog({super.key, required this.previewData, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final validRows = previewData.where((r) => r['isValid']).length;
    final previewRows = previewData.length;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.preview),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${l10n.preview}: $fileName', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Showing first $previewRows rows. $validRows/${previewData.length} valid.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 8,
                    columns: [
                      const DataColumn(label: Text('Row')),
                      DataColumn(label: Text(l10n.drivers)),
                      const DataColumn(label: Text('Brutto')),
                      DataColumn(label: Text(l10n.status)),
                    ],
                    rows: previewData.map((row) {
                      final bool isValid = row['isValid'];
                      return DataRow(
                        cells: [
                          DataCell(Text(row['row'].toString())),
                          DataCell(Text(row['driver'], overflow: TextOverflow.ellipsis)),
                          DataCell(Text(row['brutto'].toString())),
                          DataCell(Icon(
                            isValid ? Icons.check_circle : Icons.error,
                            color: isValid ? Colors.green : Colors.red,
                            size: 18,
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (validRows < previewData.length) ...[
              const SizedBox(height: 16),
              Text(
                l10n.incompleteRowsSkipped,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.back)),
        FilledButton(
          onPressed: validRows > 0 ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.startImport),
        ),
      ],
    );
  }
}



class NameMismatchDialog extends StatefulWidget {
  final String unmatchedName;

  const NameMismatchDialog({super.key, required this.unmatchedName});

  @override
  State<NameMismatchDialog> createState() => _NameMismatchDialogState();
}

class _NameMismatchDialogState extends State<NameMismatchDialog> {
  String? _selectedDriverId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final drivers = DatabaseService.getActiveDrivers();
    
    // Safety check
    if (_selectedDriverId != null && !drivers.any((d) => d.id == _selectedDriverId)) {
      _selectedDriverId = null;
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_search),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.unmatchedDriver, overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.driverNotFound(widget.unmatchedName), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n.linkToExisting, style: const TextStyle(fontSize: 12)),
          DropdownButtonFormField<String>(
            value: _selectedDriverId,
            items: drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
            onChanged: (v) => setState(() => _selectedDriverId = v),
            decoration: InputDecoration(hintText: l10n.drivers),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('OR')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final newId = const Uuid().v4();
                final driver = Driver(
                  id: newId,
                  name: widget.unmatchedName,
                  commissionRate: DatabaseService.getDefaultCommissionRate(),
                );
                await SupabaseService.upsertDriver(driver);
                await SupabaseService.saveDriverAlias(widget.unmatchedName, newId);
                await DatabaseService.saveDriverAlias(widget.unmatchedName, newId);
                if (!context.mounted) return;
                Navigator.pop(context, newId);
              },
              child: Text(l10n.createNewDriver),
            ),
          ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.skipRow)),
        FilledButton(
          onPressed: _selectedDriverId == null ? null : () async {
            await SupabaseService.saveDriverAlias(widget.unmatchedName, _selectedDriverId!);
            await DatabaseService.saveDriverAlias(widget.unmatchedName, _selectedDriverId!);
            if (!context.mounted) return;
            Navigator.pop(context, _selectedDriverId);
          },
          child: Text(l10n.mapAndContinue),
        ),
      ],
    );
  }
}
