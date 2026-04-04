import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:class_twin/core/constants.dart';
import 'package:class_twin/core/providers/preferences_provider.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final session = Supabase.instance.client.auth.currentSession;
    dev.log('[Auth] Init — session exists: \${session != null}', name: 'AuthNotifier');
    state = AsyncValue.data(session?.user);

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      dev.log('[Auth] onAuthStateChange — event: \${data.event}, user: \${data.session?.user?.email}', name: 'AuthNotifier');
      state = AsyncValue.data(data.session?.user);
      if (data.session?.user != null) {
        final name = data.session?.user.userMetadata?['full_name'] as String?;
        if (name != null) {
          _ref.read(studentNameProvider.notifier).setName(name);
        }
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(Supabase.instance.client.auth.currentUser);
    } catch (e, stack) {
      dev.log('[Auth] ERROR: \$e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
        },
      );
      state = AsyncValue.data(res.user);
    } catch (e, stack) {
      dev.log('[Auth] ERROR: \$e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e, stack) {
      dev.log('[Auth] ERROR Reset Password: \$e', name: 'AuthNotifier', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    dev.log('[Auth] Signing out...', name: 'AuthNotifier');
    await Supabase.instance.client.auth.signOut();
    dev.log('[Auth] Signed out successfully', name: 'AuthNotifier');
  }
}
