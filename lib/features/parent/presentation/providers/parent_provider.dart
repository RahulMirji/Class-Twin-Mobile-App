import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:class_twin/features/parent/domain/models/parent_report.dart';
import 'package:class_twin/core/providers/auth_provider.dart';

final parentReportsProvider = FutureProvider<List<ParentReport>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final childEmail = authState.value?.childEmail;

  if (childEmail == null || childEmail.isEmpty) {
    dev.log('[ParentProvider] No child_email found in AppUser', name: 'ParentReports');
    return [];
  }

  try {
    dev.log('[ParentProvider] Fetching reports for child email: \$childEmail', name: 'ParentReports');
    final response = await Supabase.instance.client
        .from('parent_reports')
        .select()
        .eq('email', childEmail)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ParentReport.fromJson(json)).toList();
  } catch (e, stack) {
    dev.log('[ParentProvider] ERROR fetching reports: \$e', name: 'ParentReports', error: e, stackTrace: stack);
    return [];
  }
});
