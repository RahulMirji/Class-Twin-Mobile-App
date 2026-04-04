import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    dev.log('[Auth] Init — session exists: ${session != null}', name: 'AuthNotifier');
    state = AsyncValue.data(session?.user);

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      dev.log('[Auth] onAuthStateChange — event: ${data.event}, user: ${data.session?.user?.email}', name: 'AuthNotifier');
      state = AsyncValue.data(data.session?.user);
      if (data.session?.user != null) {
        final name = data.session?.user.userMetadata?['full_name'] as String?;
        if (name != null) {
          _ref.read(studentNameProvider.notifier).setName(name);
        }
      }
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      
      dev.log('[Auth] Starting Google Sign-In...', name: 'AuthNotifier');
      dev.log('[Auth] serverClientId: ${AppConstants.googleWebClientId}', name: 'AuthNotifier');
      
      final dynamic googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId,
      );
      
      dev.log('[Auth] GoogleSignIn instance created, calling signIn()...', name: 'AuthNotifier');
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        dev.log('[Auth] User cancelled Google Sign-In', name: 'AuthNotifier');
        state = AsyncValue.data(Supabase.instance.client.auth.currentUser);
        return;
      }

      dev.log('[Auth] Google user: ${googleUser.email}', name: 'AuthNotifier');
      dev.log('[Auth] Getting authentication tokens...', name: 'AuthNotifier');
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      dev.log('[Auth] idToken present: ${idToken != null}', name: 'AuthNotifier');
      dev.log('[Auth] accessToken present: ${accessToken != null}', name: 'AuthNotifier');

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      dev.log('[Auth] Sending tokens to Supabase signInWithIdToken...', name: 'AuthNotifier');
      
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      dev.log('[Auth] Supabase sign-in successful!', name: 'AuthNotifier');
    } catch (e, stack) {
      dev.log('[Auth] ERROR: $e', name: 'AuthNotifier', error: e, stackTrace: stack);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    dev.log('[Auth] Signing out...', name: 'AuthNotifier');
    final dynamic googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await Supabase.instance.client.auth.signOut();
    dev.log('[Auth] Signed out successfully', name: 'AuthNotifier');
  }
}
