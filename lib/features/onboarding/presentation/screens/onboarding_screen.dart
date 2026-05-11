import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/locale_provider.dart';

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
  final _childEmailController = TextEditingController();

  String _selectedRole = 'student';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _childEmailController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit(dynamic tr) async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_mode == AuthMode.login) {
        try {
          await ref.read(authStateProvider.notifier).signInParent(email, password);
        } catch (_) {
          await ref.read(authStateProvider.notifier).signInWithEmail(email, password);
        }
      } else if (_mode == AuthMode.register) {
        if (_selectedRole == 'parent') {
          await ref.read(authStateProvider.notifier).signUpParent(
            name,
            email,
            password,
            _childEmailController.text.trim(),
          );
        } else {
          await ref.read(authStateProvider.notifier).signUpWithEmail(
            name, 
            email, 
            password,
            role: 'student',
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.get('account_created_login') ?? 'Account created. Please log in.')),
        );
      } else if (_mode == AuthMode.forgotPassword) {
        await ref.read(authStateProvider.notifier).resetPassword(email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.get('password_reset_sent'))),
        );
        _switchMode(AuthMode.login);
        return;
      }

      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      if (authState is AsyncData && authState.value != null && _mode != AuthMode.forgotPassword) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('AuthException', tr.get('error')))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    final title = _mode == AuthMode.login 
        ? tr.get('welcome_back') 
        : _mode == AuthMode.register 
            ? tr.get('join_class_twin') 
            : tr.get('reset_password');

    final subtitle = _mode == AuthMode.login 
        ? tr.get('login_to_continue') 
        : _mode == AuthMode.register 
            ? tr.get('create_account_join') 
            : tr.get('enter_email_reset');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        // Sage gradient background
        decoration: const BoxDecoration(
          gradient: AppTheme.onboardingGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (_mode == AuthMode.forgotPassword)
                Positioned(
                  top: 8,
                  left: 4,
                  child: IconButton(
                    icon: Icon(PhosphorIconsRegular.arrowLeft, color: AppTheme.textPrimary),
                    onPressed: () => _switchMode(AuthMode.login),
                  ),
                ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Logo
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 108,
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.85, 0.85)),
                        ),

                        const SizedBox(height: 44),

                        // Title
                        Text(
                          title,
                          style: AppTheme.displayMedium.copyWith(
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ).animate(key: ValueKey(title)).fadeIn().slideX(begin: -0.05),

                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          subtitle,
                          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                        ).animate(key: ValueKey(subtitle)).fadeIn().slideX(begin: -0.05),

                        const SizedBox(height: 40),

                        // Form fields
                        if (_mode == AuthMode.register) ...[
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text(tr.get('student') ?? 'Student', style: AppTheme.bodyMedium),
                                  value: 'student',
                                  groupValue: _selectedRole,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) => setState(() => _selectedRole = v!),
                                  activeColor: AppTheme.primary,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text(tr.get('parent') ?? 'Parent', style: AppTheme.bodyMedium),
                                  value: 'parent',
                                  groupValue: _selectedRole,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) => setState(() => _selectedRole = v!),
                                  activeColor: AppTheme.primary,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(),
                          const SizedBox(height: 14),

                          _buildInput(
                            controller: _nameController,
                            label: tr.get('full_name'),
                            icon: PhosphorIconsRegular.user,
                            enabled: !isLoading,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v!.isEmpty ? tr.get('name_required') : null,
                          ).animate().fadeIn(),
                          const SizedBox(height: 14),

                          if (_selectedRole == 'parent') ...[
                            _buildInput(
                              controller: _childEmailController,
                              label: tr.get('child_email') ?? "Child's Email",
                              icon: PhosphorIconsRegular.student,
                              enabled: !isLoading,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (_selectedRole == 'parent' && (v == null || v.isEmpty || !v.contains('@'))) {
                                  return tr.get('valid_email_required') ?? "Valid email required";
                                }
                                return null;
                              },
                            ).animate().fadeIn(),
                            const SizedBox(height: 14),
                          ],
                        ],

                        _buildInput(
                          controller: _emailController,
                          label: tr.get('email_address'),
                          icon: PhosphorIconsRegular.envelope,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => !v!.contains('@') ? tr.get('valid_email_required') : null,
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 14),

                        if (_mode != AuthMode.forgotPassword) ...[
                          _buildInput(
                            controller: _passwordController,
                            label: tr.get('password'),
                            icon: PhosphorIconsRegular.lockKey,
                            enabled: !isLoading,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                                color: AppTheme.textTertiary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => v!.length < 6 ? tr.get('password_length_required') : null,
                          ).animate().fadeIn(delay: 200.ms),
                        ],

                        if (_mode == AuthMode.login)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _switchMode(AuthMode.forgotPassword),
                              child: Text(
                                tr.get('forgot_password'),
                                style: AppTheme.labelMedium.copyWith(color: AppTheme.primary),
                              ),
                            ),
                          ).animate().fadeIn(),

                        const SizedBox(height: 28),

                        // CTA Button — full pill
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(tr),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.onPrimary,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _mode == AuthMode.login 
                                        ? tr.get('log_in') 
                                        : _mode == AuthMode.register 
                                            ? tr.get('sign_up') 
                                            : tr.get('send_reset_link'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 24),

                        if (_mode != AuthMode.forgotPassword)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _mode == AuthMode.login ? tr.get('dont_have_account') : tr.get('already_have_account'),
                                style: AppTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () => _switchMode(_mode == AuthMode.login ? AuthMode.register : AuthMode.login),
                                child: Text(
                                  _mode == AuthMode.login ? tr.get('sign_up') : tr.get('log_in'),
                                  style: AppTheme.labelLarge.copyWith(color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textTertiary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
