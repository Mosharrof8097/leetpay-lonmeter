import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final stream = Supabase.instance.client.auth.onAuthStateChange;
  stream.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      SupabaseService.migrateFromHive();
    }
  });
  return stream;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user;
});
