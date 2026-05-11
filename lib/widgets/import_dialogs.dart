import 'package:flutter/material.dart';
import '../services/file_import_service.dart';
import '../services/database_service.dart';
import '../models/driver.dart';
import 'package:uuid/uuid.dart';

class AutoMappingDialog extends StatefulWidget {
  final List<String> headers;
  final String platformId;

  const AutoMappingDialog({super.key, required this.headers, required this.platformId});

  @override
  State<AutoMappingDialog> createState() => _AutoMappingDialogState();
}

class _AutoMappingDialogState extends State<AutoMappingDialog> {
  final _mapping = ColumnMapping();
  bool _savePreference = true;

  @override
  void initState() {
    super.initState();
    _initializeMapping();
  }

  void _initializeMapping() {
    // 1. Try to load saved preference
    final saved = DatabaseService.getSetting('mapping_${widget.platformId}');
    if (saved != null) {
      _mapping.driverNameIdx = saved['driverNameIdx'] ?? -1;
      _mapping.bruttoIdx = saved['bruttoIdx'] ?? -1;
      _mapping.nettoIdx = saved['nettoIdx'] ?? -1;
      _mapping.weekIdx = saved['weekIdx'] ?? -1;
      _mapping.dricksIdx = saved['dricksIdx'] ?? -1;
      _mapping.dateIdx = saved['dateIdx'] ?? -1;
      
      // Validate that saved indices are still within bounds of current headers
      if (_mapping.driverNameIdx >= widget.headers.length) _mapping.driverNameIdx = -1;
      if (_mapping.bruttoIdx >= widget.headers.length) _mapping.bruttoIdx = -1;
      if (_mapping.nettoIdx >= widget.headers.length) _mapping.nettoIdx = -1;
      if (_mapping.weekIdx >= widget.headers.length) _mapping.weekIdx = -1;
      if (_mapping.dricksIdx >= widget.headers.length) _mapping.dricksIdx = -1;
      if (_mapping.dateIdx >= widget.headers.length) _mapping.dateIdx = -1;
    }

    // 2. If any field is still -1, try to guess based on keywords
    if (_mapping.driverNameIdx == -1) {
      _mapping.driverNameIdx = FileImportService.findBestColumnMatch(widget.headers, ['Driver Name', 'driver', 'name', 'förare', 'namn', 'alias']);
    }
    if (_mapping.bruttoIdx == -1) {
      _mapping.bruttoIdx = FileImportService.findBestColumnMatch(widget.headers, ['Brutto Amount', 'brutto', 'amount', 'inkört', 'belopp', 'total', 'revenue', 'gross']);
    }
    if (_mapping.nettoIdx == -1) {
      _mapping.nettoIdx = FileImportService.findBestColumnMatch(widget.headers, ['Netto Amount', 'netto', 'earnings', 'net', 'payout', 'to pay']);
    }
    if (_mapping.weekIdx == -1) {
      _mapping.weekIdx = FileImportService.findBestColumnMatch(widget.headers, ['Week', 'week', 'vecka', 'wk']);
    }
    if (_mapping.dricksIdx == -1) {
      _mapping.dricksIdx = FileImportService.findBestColumnMatch(widget.headers, ['Tips', 'tips', 'dricks', 'gratuity']);
    }
    if (_mapping.dateIdx == -1) {
      _mapping.dateIdx = FileImportService.findBestColumnMatch(widget.headers, ['Date', 'date', 'datum', 'tid', 'time']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Map Columns'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropdown('Driver Name', _mapping.driverNameIdx, (v) => setState(() => _mapping.driverNameIdx = v!)),
            _buildDropdown('Brutto Amount', _mapping.bruttoIdx, (v) => setState(() => _mapping.bruttoIdx = v!)),
            _buildDropdown('Netto/Earnings (Required for fee deduction)', _mapping.nettoIdx, (v) => setState(() => _mapping.nettoIdx = v!)),
            _buildDropdown('Week Number', _mapping.weekIdx, (v) => setState(() => _mapping.weekIdx = v!)),
            _buildDropdown('Tips (Optional)', _mapping.dricksIdx, (v) => setState(() => _mapping.dricksIdx = v!)),
            _buildDropdown('Date (If no week)', _mapping.dateIdx, (v) => setState(() => _mapping.dateIdx = v!)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Save mapping for this platform', style: TextStyle(fontSize: 13)),
              value: _savePreference,
              onChanged: (v) => setState(() => _savePreference = v!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), 
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _mapping.isValid ? () {
            final navigator = Navigator.of(context);
            if (_savePreference) {
              DatabaseService.saveSetting('mapping_${widget.platformId}', _mapping.toMap());
            }
            if (navigator.canPop()) {
              navigator.pop(_mapping);
            }
          } : null,
          child: const Text('Start Import'),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, int current, ValueChanged<int?> onChanged) {
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
          const DropdownMenuItem(value: -1, child: Text('None')),
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
    final drivers = DatabaseService.getActiveDrivers();
    
    // Safety check
    if (_selectedDriverId != null && !drivers.any((d) => d.id == _selectedDriverId)) {
      _selectedDriverId = null;
    }

    return AlertDialog(
      title: const Text('Unmatched Driver'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Driver '${widget.unmatchedName}' from file not found."),
          const SizedBox(height: 16),
          const Text('Link to existing:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          DropdownButtonFormField<String>(
            value: _selectedDriverId,
            items: drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
            onChanged: (v) => setState(() => _selectedDriverId = v),
            decoration: const InputDecoration(hintText: 'Select Driver'),
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
                await DatabaseService.addDriver(driver);
                await DatabaseService.saveDriverAlias(widget.unmatchedName, newId);
                if (!context.mounted) return;
                Navigator.pop(context, newId);
              },
              child: const Text('Create New Driver'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip Row')),
        FilledButton(
          onPressed: _selectedDriverId == null ? null : () async {
            await DatabaseService.saveDriverAlias(widget.unmatchedName, _selectedDriverId!);
            if (!context.mounted) return;
            Navigator.pop(context, _selectedDriverId);
          },
          child: const Text('Map & Continue'),
        ),
      ],
    );
  }
}
