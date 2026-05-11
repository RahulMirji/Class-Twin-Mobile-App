import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/session.dart';
import '../../domain/session_state.dart';
import '../providers/session_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/peer_recommendation_provider.dart';
import '../../domain/models/peer_recommendation.dart';

/// SessionEndScreen — Session has ended, show summary
class SessionEndScreen extends ConsumerWidget {
  const SessionEndScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
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
                          tr.get('session_complete'),
                          style: AppTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 12),

                        Text(
                          tr.get('great_work'),
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
                                  '${s.totalRounds} ${tr.get('rounds_completed')}',
                                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                        const SizedBox(height: 32),

                        // Peer Recommendation Card
                        Consumer(
                          builder: (context, ref, child) {
                            final peerAsync = ref.watch(peerRecommendationProvider(s.id));
                            return peerAsync.when(
                              data: (peer) {
                                if (peer == null) return const SizedBox.shrink();
                                return _buildPeerRecommendationCard(context, peer, tr)
                                    .animate()
                                    .fadeIn(delay: 800.ms, duration: 600.ms)
                                    .slideY(begin: 0.1, end: 0);
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => const SizedBox.shrink(),
                            );
                          },
                        ),

                        const Spacer(flex: 3),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(sessionStateProvider.notifier).leaveSession();
                              context.go('/');
                            },
                            child: Text(tr.get('return_home'), style: const TextStyle(fontSize: 16)),
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

  Widget _buildPeerRecommendationCard(BuildContext context, PeerRecommendation peer, dynamic tr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F0E8), Color(0xFFDDEBDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.2)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  PhosphorIconsFill.usersThree,
                  color: AppTheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Peer Study Buddy',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.tertiary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Struggling with this topic? ${peer.studentName} did really well and also speaks ${peer.language}. Reach out to them!',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening chat with ${peer.studentName}... (Coming Soon)'),
                    backgroundColor: AppTheme.tertiary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(PhosphorIconsRegular.chatCircleDots, size: 20),
              label: Text('Message ${peer.studentName}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiary,
                foregroundColor: AppTheme.onTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

