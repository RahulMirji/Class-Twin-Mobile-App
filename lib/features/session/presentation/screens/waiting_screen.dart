import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/student.dart';
import '../../domain/session_state.dart';
import '../providers/session_provider.dart';

/// WaitingScreen — Between questions / after response
class WaitingScreen extends ConsumerWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);
    final mode = ref.watch(studentModeProvider);

    if (sessionState is! SessionWaiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = sessionState;
    final hasResponse = state.lastResponse != null;

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

                        // State icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: hasResponse
                                ? AppTheme.tertiary.withValues(alpha: 0.12)
                                : AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                            boxShadow: hasResponse
                                ? [BoxShadow(
                                    color: AppTheme.tertiary.withValues(alpha: 0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  )]
                                : AppTheme.ambientShadowWarm,
                          ),
                          child: Icon(
                            hasResponse
                                ? PhosphorIconsBold.checkCircle
                                : PhosphorIconsRegular.hourglassMedium,
                            size: 36,
                            color: hasResponse ? AppTheme.tertiary : AppTheme.primary,
                          ),
                        ).animate().scaleXY(begin: 0.8, end: 1, duration: 500.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 24),

                        Text(
                          hasResponse
                              ? 'Response submitted'
                              : 'Waiting for next question...',
                          style: AppTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 10),

                        Text(
                          'Your teacher will share the next question shortly.',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                        if (hasResponse) ...[
                          const SizedBox(height: 24),
                          _ResponseChip(response: state.lastResponse!.response),
                        ],

                        const Spacer(flex: 3),

                        // Remote action buttons
                        if (mode == StudentMode.remote) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: PhosphorIconsBold.chatDots,
                                  label: 'Chat',
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: PhosphorIconsBold.handPalm,
                                  label: 'Raise Hand',
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
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

class _ResponseChip extends StatelessWidget {
  final String response;

  const _ResponseChip({required this.response});

  Color get _color {
    switch (response) {
      case 'got_it':
        return AppTheme.responseGotIt;
      case 'somewhat':
        return AppTheme.responseSomewhat;
      case 'lost':
        return AppTheme.responseLost;
      default:
        return AppTheme.textTertiary;
    }
  }

  String get _label {
    switch (response) {
      case 'got_it':
        return 'Got It ✓';
      case 'somewhat':
        return 'Somewhat';
      case 'lost':
        return 'Lost';
      default:
        return response;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Text(
        _label,
        style: AppTheme.labelMedium.copyWith(color: _color, fontWeight: FontWeight.w600),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surfaceContainerLowest,
          side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.textPrimary),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
