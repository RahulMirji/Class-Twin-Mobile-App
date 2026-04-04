import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/preferences_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(studentNameProvider.notifier).setName(name);

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      
      final authState = ref.read(authStateProvider);
      if (authState is AsyncData && authState.value != null) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),

                      // Welcome Text
                      Text(
                        "Welcome to ClassTwin",
                        style: AppTheme.displayMedium.copyWith(
                          color: AppTheme.textPrimary,
                          letterSpacing: -1,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),

                      const SizedBox(height: 12),
                      Text(
                        'To personalize your learning journey, we\'d love to know how to address you in our digital atelier.',
                        style: AppTheme.bodyLarge,
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                      const SizedBox(height: 48),

                      // Name input
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: AppTheme.titleLarge,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: AppTheme.titleLarge.copyWith(
                            color: AppTheme.textTertiary.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _submitName(),
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                      const SizedBox(height: 24),

                      // Or divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: AppTheme.labelSmall),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 24),

                      // Google Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.surfaceContainerLow, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsFill.googleLogo, size: 24, color: AppTheme.primary),
                              const SizedBox(width: 12),
                              const Text('Continue with Google'),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 550.ms),

                      const Spacer(),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Continue'),
                                    const SizedBox(width: 8),
                                    Icon(
                                      PhosphorIconsBold.arrowRight,
                                      size: 18,
                                      color: AppTheme.onPrimary,
                                    ),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms of Service',
                          style: AppTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
