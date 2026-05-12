import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import 'preferences_provider.dart';
import '../l10n/app_localizations.dart';

class LocaleNotifier extends StateNotifier<String> {
  static const _key = 'app_locale';
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(_prefs.getString(_key) ?? 'en');

  Future<void> setLocale(String code) async {
    await _prefs.setString(_key, code);
    state = code;

    // Sync to database if user is logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      final email = currentUser.email;
      final name = currentUser.userMetadata?['full_name'] as String? ?? 'Student';
      if (email != null) {
        try {
          // Try update first
          final res = await Supabase.instance.client
              .from('students')
              .update({'language': code})
              .eq('email', email)
              .select();
          
          if (res == null || (res as List).isEmpty) {
            // No row existed — insert a new one
            await Supabase.instance.client.from('students').insert({
              'email': email,
              'name': name,
              'language': code,
              'auth_id': currentUser.id,
              'role': 'student',
            });
            dev.log('[Locale] Inserted new student row with language $code', name: 'LocaleNotifier');
          } else {
            dev.log('[Locale] Synced language $code to students table', name: 'LocaleNotifier');
          }
        } catch (e) {
          dev.log('[Locale] Failed to sync language to database: $e', name: 'LocaleNotifier');
        }
      }
    }
  }

}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

final trProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});
