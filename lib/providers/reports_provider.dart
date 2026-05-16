import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monthly_payroll.dart';

/// Fetches finalized settlements from Supabase for a specific period
final settledReportsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({int month, int year})>((ref, params) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await supabase
      .from('settlements')
      .select('*, drivers(name)')
      .eq('owner_id', userId)
      .eq('period_month', params.month)
      .eq('period_year', params.year);
  
  return (response as List).cast<Map<String, dynamic>>();
});
