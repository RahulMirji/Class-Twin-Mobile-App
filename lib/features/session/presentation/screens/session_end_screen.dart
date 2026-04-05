import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/session.dart';
import '../../domain/session_state.dart';
import '../providers/session_provider.dart';

/// SessionEndScreen — Session has ended, show summary
class SessionEndScreen extends ConsumerWidget {
  const SessionEndScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);

    Session? session;
    if (sessionState is SessionEnded) {
      session = sessionState.session;
    }

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final s = session;

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
                      children: [
                        const Spacer(flex: 2),

                        // Success icon — larger, warm green glow
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppTheme.tertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.tertiary.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PhosphorIconsBold.checkCircle,
                            size: 48,
                            color: AppTheme.tertiary,
                          ),
                        ).animate().scaleXY(begin: 0.4, end: 1, duration: 700.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 32),

                        Text(
                          'Session Complete',
                          style: AppTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 12),

                        Text(
                          'Great work! Your responses have been recorded.',
                          style: AppTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                        const SizedBox(height: 32),

                        // Summary card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: const Icon(
                                  PhosphorIconsRegular.bookOpen,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s.topic,
                                style: AppTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Text(
                                  '${s.totalRounds} rounds completed',
                                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                        const Spacer(flex: 3),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(sessionStateProvider.notifier).leaveSession();
                              context.go('/');
                            },
                            child: const Text('Return Home', style: TextStyle(fontSize: 16)),
                          ),
                        ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

                        const SizedBox(height: 32),
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
