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
      if (email != null) {
        try {
          await Supabase.instance.client
              .from('students')
              .update({'language': code})
              .eq('email', email);
          dev.log('[Locale] Synced language \$code to students table', name: 'LocaleNotifier');
        } catch (e) {
          dev.log('[Locale] Failed to sync language to database: \$e', name: 'LocaleNotifier');
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
