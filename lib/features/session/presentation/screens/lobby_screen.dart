import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/session.dart';
import '../../domain/models/student.dart';
import '../../domain/session_state.dart';
import '../providers/session_provider.dart';

/// LobbyScreen — Waiting for session to start
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);
    final mode = ref.watch(studentModeProvider);
    final isRemote = mode == StudentMode.remote;

    Session? session;
    if (sessionState is SessionLobby) {
      session = sessionState.session;
    } else if (sessionState is SessionStreamPending) {
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

                        // Animated waiting icon
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                            boxShadow: AppTheme.ambientShadowWarm,
                          ),
                          child: Icon(
                            isRemote
                                ? PhosphorIconsRegular.broadcast
                                : PhosphorIconsRegular.hourglassMedium,
                            size: 40,
                            color: AppTheme.primary,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 1, end: 1.06, duration: 2000.ms),

                        const SizedBox(height: 32),

                        Text(
                          isRemote ? 'Stream starting soon.' : 'Waiting for class...',
                          style: AppTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 600.ms),

                        const SizedBox(height: 12),

                        Text(
                          isRemote
                              ? 'Your teacher will go live shortly.'
                              : 'Your teacher will start the session soon.',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 40),

                        // Session info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SESSION TOPIC',
                                style: AppTheme.labelSmall.copyWith(
                                  letterSpacing: 1.2,
                                  color: AppTheme.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s.topic,
                                style: AppTheme.headlineMedium,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _InfoChip(
                                    icon: PhosphorIconsRegular.listNumbers,
                                    label: '${s.totalRounds} rounds',
                                  ),
                                  const SizedBox(width: 10),
                                  _InfoChip(
                                    icon: isRemote
                                        ? PhosphorIconsRegular.monitor
                                        : PhosphorIconsRegular.mapPin,
                                    label: isRemote ? 'Remote' : 'In Room',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                        const Spacer(flex: 3),

                        // Subtle shimmer loading bar
                        Container(
                          width: 100,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: LinearProgressIndicator(
                            backgroundColor: AppTheme.surfaceContainer,
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            minHeight: 3,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(
                              duration: 1500.ms,
                              color: AppTheme.primary.withValues(alpha: 0.15),
                            ),

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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
