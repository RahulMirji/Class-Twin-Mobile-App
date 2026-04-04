import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../../core/demo_data.dart';
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
    } else {
      // Demo mode fallback
      session = DemoData.session;
    }

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
                    children: [
                      const Spacer(flex: 2),

                      // Success icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                        ),
                        child: const Icon(
                          PhosphorIconsBold.checkCircle,
                          size: 40,
                          color: AppTheme.tertiary,
                        ),
                      ).animate().scaleXY(begin: 0.5, end: 1, duration: 600.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 32),

                      // Text
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

                      if (session != null) ...[
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          child: Column(
                            children: [
                              Text(
                                session.topic ?? '',
                                style: AppTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${session.totalRounds} rounds completed',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                      ],

                      const Spacer(flex: 3),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(sessionStateProvider.notifier).leaveSession();
                            context.go('/');
                          },
                          child: const Text('Return Home'),
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
    );
  }
}
