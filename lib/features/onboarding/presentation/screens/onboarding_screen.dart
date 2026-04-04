import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/auth_provider.dart';

enum AuthMode { login, register, forgotPassword }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  AuthMode _mode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_mode == AuthMode.login) {
        await ref.read(authStateProvider.notifier).signInWithEmail(email, password);
      } else if (_mode == AuthMode.register) {
        await ref.read(authStateProvider.notifier).signUpWithEmail(name, email, password);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Logging you in...')),
        );
      } else if (_mode == AuthMode.forgotPassword) {
        await ref.read(authStateProvider.notifier).resetPassword(email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
        _switchMode(AuthMode.login);
        return; // Don't redirect on forgot password
      }

      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      if (authState is AsyncData && authState.value != null && _mode != AuthMode.forgotPassword) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('AuthException', 'Error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    final title = _mode == AuthMode.login 
        ? 'Welcome Back' 
        : _mode == AuthMode.register 
            ? 'Join ClassTwin' 
            : 'Reset Password';

    final subtitle = _mode == AuthMode.login 
        ? 'Log in to your account to continue' 
        : _mode == AuthMode.register 
            ? 'Create an account to join the classroom' 
            : 'Enter your email to receive a reset link';

    return Scaffold(
      appBar: _mode == AuthMode.forgotPassword 
          ? AppBar(
              leading: IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowLeft),
                onPressed: () => _switchMode(AuthMode.login),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.displayMedium.copyWith(
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ).animate(key: ValueKey(title)).fadeIn().slideX(),

                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: AppTheme.bodyLarge,
                  ).animate(key: ValueKey(subtitle)).fadeIn().slideX(),

                  const SizedBox(height: 48),

                  if (_mode == AuthMode.register) ...[
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(PhosphorIconsRegular.user),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(PhosphorIconsRegular.envelope),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) => !v!.contains('@') ? 'Please enter a valid email' : null,
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 16),

                  if (_mode != AuthMode.forgotPassword) ...[
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(PhosphorIconsRegular.lockKey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  if (_mode == AuthMode.login)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _switchMode(AuthMode.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: AppTheme.labelMedium.copyWith(color: AppTheme.primary),
                        ),
                      ),
                    ).animate().fadeIn(),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                          : Text(
                              _mode == AuthMode.login 
                                  ? 'Log In' 
                                  : _mode == AuthMode.register 
                                      ? 'Sign Up' 
                                      : 'Send Reset Link',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 24),

                  if (_mode != AuthMode.forgotPassword)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mode == AuthMode.login ? "Don't have an account?" : "Already have an account?",
                          style: AppTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => _switchMode(_mode == AuthMode.login ? AuthMode.register : AuthMode.login),
                          child: Text(
                            _mode == AuthMode.login ? "Sign Up" : "Log In",
                            style: AppTheme.labelLarge.copyWith(color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
