import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import 'qr_scan_screen.dart';

/// HomeScreen — Enter session code to join
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _scanQR() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QRScanScreen()),
    );
    if (result != null && result is String && result.isNotEmpty) {
      _codeController.text = result;
      _onJoin();
    }
  }

  void _onJoin() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    context.go('/join/$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.onboardingGradient),
        child: SafeArea(
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
                        const SizedBox(height: 56),

                        Text(
                          'Join Session',
                          style: AppTheme.displayLarge.copyWith(
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1),

                        const SizedBox(height: 8),

                        Text(
                          'Enter your session code to join the class.',
                          style: AppTheme.bodyLarge,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 40),

                        // Session code input card
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SESSION CODE',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textTertiary,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _codeController,
                                focusNode: _focusNode,
                                textCapitalization: TextCapitalization.characters,
                                style: AppTheme.displaySmall.copyWith(
                                  letterSpacing: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'ABC123',
                                  hintStyle: AppTheme.displaySmall.copyWith(
                                    color: AppTheme.textTertiary.withValues(alpha: 0.35),
                                    letterSpacing: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceContainerLow,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(PhosphorIconsBold.qrCode, color: AppTheme.primary, size: 22),
                                    onPressed: _scanQR,
                                  ),
                                ),
                                onSubmitted: (_) => _onJoin(),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.08),

                        const SizedBox(height: 20),

                        // Join button — full pill
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _onJoin,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Join Session', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Icon(
                                  PhosphorIconsBold.arrowRight,
                                  size: 18,
                                  color: AppTheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                        const Spacer(),

                        // Branding
                        Center(
                          child: Text(
                            'ClassTwin',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textTertiary.withValues(alpha: 0.5),
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}
