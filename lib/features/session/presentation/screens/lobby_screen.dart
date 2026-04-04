import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../../core/demo_data.dart';
import '../../domain/models/session.dart';
import '../../domain/models/student.dart';
import '../../domain/session_state.dart';
import '../providers/session_provider.dart';

/// LobbyScreen — Waiting for session to start
/// Remote students see "Stream starting soon" state
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

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                        ),
                        child: Icon(
                          isRemote
                              ? PhosphorIconsRegular.broadcast
                              : PhosphorIconsRegular.hourglassMedium,
                          size: 36,
                          color: AppTheme.textTertiary,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 1, end: 1.05, duration: 2000.ms),

                      const SizedBox(height: 32),

                      // Title
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
                      if (session != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session Topic',
                                style: AppTheme.labelSmall.copyWith(
                                  letterSpacing: 1,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                session.topic,
                                style: AppTheme.headlineMedium,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _InfoChip(
                                    icon: PhosphorIconsRegular.listNumbers,
                                    label: '${session.totalRounds} rounds',
                                  ),
                                  const SizedBox(width: 12),
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

                      // Subtle loading indicator
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          backgroundColor: AppTheme.surfaceContainer,
                          color: AppTheme.textTertiary.withValues(alpha: 0.3),
                          minHeight: 2,
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(
                            duration: 1500.ms,
                            color: AppTheme.surfaceContainerHigh,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.labelSmall),
        ],
      ),
    );
  }
}
