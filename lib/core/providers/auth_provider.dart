import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:class_twin/core/providers/preferences_provider.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  // Use aliased version to avoid any naming conflicts
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    clientId: '1012466165958-0qg202r92evkasgdcldgr4d8tail3jp8.apps.googleusercontent.com',
  );

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final session = Supabase.instance.client.auth.currentSession;
    state = AsyncValue.data(session?.user);

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
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
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = AsyncValue.data(Supabase.instance.client.auth.currentUser);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await Supabase.instance.client.auth.signOut();
  }
}
