import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:class_twin/core/constants.dart';
import 'package:class_twin/core/providers/preferences_provider.dart';
import 'package:class_twin/core/providers/locale_provider.dart';
import 'package:class_twin/core/models/app_user.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Check local SharedPreferences for parent session
    final prefs = _ref.read(sharedPreferencesProvider);
    final parentJson = prefs.getString('parent_session');
    
    if (parentJson != null) {
      dev.log('[Auth] Parent session found locally', name: 'AuthNotifier');
      final parentData = jsonDecode(parentJson);
      state = AsyncValue.data(AppUser.fromMap(parentData));
      return; // Skip Supabase auth check if parent
    }

    // Otherwise, use Supabase Auth for students
    final session = Supabase.instance.client.auth.currentSession;
    dev.log('[Auth] Init — session exists: ${session != null}', name: 'AuthNotifier');
    
    if (session?.user != null) {
      state = AsyncValue.data(_mapSupabaseUser(session!.user));
    } else {
      state = const AsyncValue.data(null);
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      // If we have a local parent session, ignore Supabase changes
      if (state.value?.role == 'parent') return;

      dev.log('[Auth] onAuthStateChange — event: ${data.event}, user: ${data.session?.user?.email}', name: 'AuthNotifier');
      if (data.session?.user != null) {
        state = AsyncValue.data(_mapSupabaseUser(data.session!.user));
        final name = data.session?.user.userMetadata?['full_name'] as String?;
        if (name != null) {
          _ref.read(studentNameProvider.notifier).setName(name);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  AppUser _mapSupabaseUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] as String? ?? 'Student',
      role: user.userMetadata?['role'] as String? ?? 'student',
      childEmail: user.userMetadata?['child_email'] as String?,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (Supabase.instance.client.auth.currentUser != null) {
        state = AsyncValue.data(_mapSupabaseUser(Supabase.instance.client.auth.currentUser!));
      }
    } catch (e, stack) {
      dev.log('[Auth] ERROR: $e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password, {String role = 'student', String? childEmail}) async {
    try {
      state = const AsyncValue.loading();
      
      final Map<String, dynamic> metadata = {
        'full_name': name,
        'role': role,
      };
      if (childEmail != null && childEmail.isNotEmpty) {
        metadata['child_email'] = childEmail;
      }

      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (res.user != null) {
        final currentLanguage = _ref.read(localeProvider);
        try {
          await Supabase.instance.client.from('students').insert({
            'email': email,
            'name': name,
            'language': currentLanguage,
            'auth_id': res.user!.id,
            'role': role,
          });
        } catch (dbErr) {
          dev.log('[Auth] Error writing to students table: $dbErr', name: 'AuthNotifier');
        }
        state = AsyncValue.data(_mapSupabaseUser(res.user!));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      dev.log('[Auth] ERROR: $e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  // --- PARENT SPECIFIC AUTHENTICATION (BYPASS SUPABASE AUTH) ---

  Future<void> signUpParent(String name, String email, String password, String childEmail) async {
    try {
      state = const AsyncValue.loading();
      final currentLanguage = _ref.read(localeProvider);
      
      // Insert directly into parents table
      final response = await Supabase.instance.client.from('parents').insert({
        'name': name,
        'email': email,
        'password': password,
        'child_email': childEmail,
        'language': currentLanguage,
      }).select().single();

      final parentUser = AppUser(
        id: response['id'],
        email: response['email'],
        name: response['name'],
        role: 'parent',
        childEmail: response['child_email'],
      );

      // Save locally
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString('parent_session', jsonEncode(parentUser.toMap()));

      state = AsyncValue.data(parentUser);
    } catch (e, stack) {
      dev.log('[Auth] ERROR signUpParent: $e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signInParent(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      
      // Query parents table directly
      final response = await Supabase.instance.client.from('parents')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invalid login credentials');
      }

      final parentUser = AppUser(
        id: response['id'],
        email: response['email'],
        name: response['name'],
        role: 'parent',
        childEmail: response['child_email'],
      );

      // Save locally
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString('parent_session', jsonEncode(parentUser.toMap()));

      state = AsyncValue.data(parentUser);
    } catch (e, stack) {
      dev.log('[Auth] ERROR signInParent: $e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e, stack) {
      dev.log('[Auth] ERROR Reset Password: $e', name: 'AuthNotifier', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    dev.log('[Auth] Signing out...', name: 'AuthNotifier');
    
    // Clear parent local session if it exists
    if (state.value?.role == 'parent') {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove('parent_session');
      state = const AsyncValue.data(null);
    } else {
      await Supabase.instance.client.auth.signOut();
    }
    
    dev.log('[Auth] Signed out successfully', name: 'AuthNotifier');
  }
}
