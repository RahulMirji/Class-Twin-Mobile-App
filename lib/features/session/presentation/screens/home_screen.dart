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
    // Navigate to JoinScreen with the session code
    context.go('/join/$code');
  }

  @override
  Widget build(BuildContext context) {
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

                      // Tab Header
                      Text(
                        'Join Session',
                        style: AppTheme.displayLarge.copyWith(
                          color: AppTheme.textPrimary,
                          letterSpacing: -1,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),

                      const SizedBox(height: 8),

                      Text(
                        'Enter your session code to join the class.',
                        style: AppTheme.bodyLarge,
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                      const SizedBox(height: 48),

                      // Session code input
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Code',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.textTertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _codeController,
                              focusNode: _focusNode,
                              textCapitalization: TextCapitalization.characters,
                              style: AppTheme.displaySmall.copyWith(
                                letterSpacing: 8,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'ABC123',
                                hintStyle: AppTheme.displaySmall.copyWith(
                                  color: AppTheme.textTertiary.withValues(alpha: 0.4),
                                  letterSpacing: 8,
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 18),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusLg),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusLg),
                                  borderSide: const BorderSide(
                                      color: AppTheme.primary, width: 1.5),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(PhosphorIconsBold.qrCode, color: AppTheme.primary),
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
                          .slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Join button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Join Session'),
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



                      const Spacer(),

                      // Bottom branding
                      Center(
                        child: Text(
                          'ClassTwin',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textTertiary.withValues(alpha: 0.5),
                            letterSpacing: 2,
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
    );
  }
}
