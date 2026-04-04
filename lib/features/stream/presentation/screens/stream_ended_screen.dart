import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../session/domain/session_state.dart';
import '../../../session/presentation/providers/session_provider.dart';

/// StreamEndedScreen — Teacher ended stream mid-session
/// PRD Section 7.6
class StreamEndedScreen extends ConsumerWidget {
  const StreamEndedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);

    // Determine if session is still active
    final isSessionActive = sessionState is SessionWaiting ||
        sessionState is SessionQuestion;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.prohibit,
                  size: 36,
                  color: AppTheme.textTertiary,
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 24),

              Text(
                'Stream has ended',
                style: AppTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 12),

              Text(
                'Your teacher stopped the broadcast. The session may still be active.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const Spacer(),

              // Active session info card
              if (isSessionActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsBold.checkCircle,
                        color: AppTheme.responseGotIt,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Session is still running — you can still respond to questions',
                          style: AppTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

              const SizedBox(height: 20),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isSessionActive) {
                      context.go('/session');
                    } else {
                      context.go('/session/ended');
                    }
                  },
                  child: Text(
                    isSessionActive ? 'Continue to Session' : 'View Summary',
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
