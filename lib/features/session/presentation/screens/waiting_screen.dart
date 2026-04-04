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

                      // Checkmark / wait icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: state.lastResponse != null
                              ? AppTheme.tertiary.withValues(alpha: 0.1)
                              : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                        ),
                        child: Icon(
                          state.lastResponse != null
                              ? PhosphorIconsBold.checkCircle
                              : PhosphorIconsRegular.hourglassMedium,
                          size: 32,
                          color: state.lastResponse != null
                              ? AppTheme.tertiary
                              : AppTheme.textTertiary,
                        ),
                      ).animate().scaleXY(begin: 0.8, end: 1, duration: 500.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 24),

                      Text(
                        state.lastResponse != null
                            ? 'Response submitted'
                            : 'Waiting for next question...',
                        style: AppTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 500.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Your teacher will share the next question shortly.',
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                      if (state.lastResponse != null) ...[
                        const SizedBox(height: 24),
                        _ResponseChip(response: state.lastResponse!.response),
                      ],

                      const Spacer(flex: 3),

                      // Remote controls
                      if (mode == StudentMode.remote) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: PhosphorIconsBold.chatDots,
                                label: 'Chat',
                                onTap: () {
                                  // Open chat panel
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                icon: PhosphorIconsBold.handPalm,
                                label: 'Raise Hand',
                                onTap: () {
                                  // Show hand raise modal
                                },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: AppTheme.labelMedium.copyWith(color: _color),
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
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
