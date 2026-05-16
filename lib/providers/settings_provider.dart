import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final companyNameProvider = StateNotifierProvider<CompanyNameNotifier, String>((ref) {

  // Watch auth state to trigger recreation (and thus refresh) when user signs in
  ref.watch(authStateProvider);
  return CompanyNameNotifier();
});

class CompanyNameNotifier extends StateNotifier<String> {
  CompanyNameNotifier() : super(DatabaseService.getCompanyName()) {
    // Attempt to sync from cloud on startup
    refresh();
  }

  Future<void> updateName(String newName) async {
    state = newName;
    await DatabaseService.saveSetting('companyName', newName);

    try {
      await SupabaseService.updateSettings({'company_name': newName});
    } catch (e) {
      print('Supabase settings sync failed: $e');
    }
  }

  Future<void> refresh() async {
    try {
      final settings = await SupabaseService.getSettings();
      final newName = settings?['company_name'] as String?;
      if (newName != null && newName.isNotEmpty) {
        await DatabaseService.saveSetting('companyName', newName);
        state = newName;
      }
    } catch (e) {
      // Silently fail if not logged in or offline
      print('Could not sync company name from cloud: $e');
    }
  }
}
