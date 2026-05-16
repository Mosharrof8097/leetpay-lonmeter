import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/import_service.dart';

class DataImportScreen extends ConsumerStatefulWidget {
  const DataImportScreen({super.key});

  @override
  ConsumerState<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends ConsumerState<DataImportScreen> {
  String _selectedPlatform = 'Bolt';
  bool _isLoading = false;

  Future<void> _startImport() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ImportService.pickAndImport(_selectedPlatform);
      
      if (mounted) {
        if (result['success']) {
          _showSuccess(result['message']);
        } else {
          _showError(result['message']);
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF7ED957), size: 60),
            const SizedBox(height: 16),
            Text('SUCCESS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7ED957),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('DATA IMPORT', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _buildHelpCard(isDark),
            ),
            const SizedBox(height: 32),
            const Text('SELECT PLATFORM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildPlatformSelector(isDark),
            const SizedBox(height: 48),
            Center(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: _buildUploadZone(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7ED957).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7ED957).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2E7D32), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Upload Bolt or Uber CSV/Excel files to automatically calculate earnings for your drivers.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector(bool isDark) {
    final platforms = ['Bolt', 'Uber', 'Other'];
    
    return Row(
      children: platforms.map((p) {
        final isSelected = _selectedPlatform == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlatform = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7ED957) : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    p == 'Bolt' ? Icons.bolt_rounded : (p == 'Uber' ? Icons.directions_car_rounded : Icons.more_horiz_rounded),
                    color: isSelected ? Colors.black : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.black : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUploadZone(bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : _startImport,
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF7ED957).withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7ED957)))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 64, color: Color(0xFF7ED957)),
                const SizedBox(height: 16),
                Text('TAP TO UPLOAD FILE', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Supports .csv, .xlsx, .xls', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
      ),
    );
  }
}
