import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:class_twin/core/theme.dart';
import 'package:class_twin/core/providers/preferences_provider.dart';
import 'package:class_twin/core/providers/notification_provider.dart';
import 'package:class_twin/features/session/presentation/providers/session_list_provider.dart';
import 'package:class_twin/features/session/presentation/providers/assignments_provider.dart';
import 'package:class_twin/features/session/domain/models/remedial_assignment.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showReminderDialog(BuildContext context, WidgetRef ref, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: Row(
          children: [
            Icon(PhosphorIconsFill.bellSimple, color: AppTheme.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Reminder Set!'),
          ],
        ),
        content: Text(
          'We will notify you before "$title" starts.',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );

    final notificationService = ref.read(notificationServiceProvider);
    notificationService.scheduleNotification(
      id: title.hashCode,
      title: 'Class Starting Soon!',
      body: '$title is about to begin. Join now!',
      scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentName = ref.watch(studentNameProvider) ?? 'Student';
    final activeSessions = ref.watch(activeSessionsProvider);
    final upcomingSessions = ref.watch(upcomingSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(activeSessionsProvider.future);
            await ref.read(upcomingSessionsProvider.future);
            await ref.read(assignedQuizzesProvider.future);
          },
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              // ─── Gradient Header ───────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.headerGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: greeting + action icons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $studentName',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getGreeting(),
                                  style: AppTheme.displaySmall.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action Buttons
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.push('/join'),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceContainerLowest,
                                  padding: const EdgeInsets.all(12),
                                ),
                                icon: Icon(
                                  PhosphorIconsRegular.plusCircle,
                                  color: AppTheme.primary,
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Body Content ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Remedial Quizzes Section ---
                      Consumer(builder: (context, ref, child) {
                        final assignments = ref.watch(assignedQuizzesProvider);
                        return assignments.when(
                          data: (List<RemedialAssignment> list) => list.isEmpty
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    _SectionHeader(title: 'Your Tasks'),
                                    const SizedBox(height: 14),
                                    ...list.map((a) => _remedialCard(context, a)),
                                    const SizedBox(height: 28),
                                  ],
                                ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      }),

                      const SizedBox(height: 8),
                      _SectionHeader(title: 'Live Classes'),
                      const SizedBox(height: 14),
                      activeSessions.when(
                        data: (sessions) => sessions.isEmpty
                            ? _buildEmptyState('No live classes at the moment.')
                            : Column(
                                children: sessions.map((s) => Column(
                                  children: [
                                    _sessionCard(context, ref, s, isLive: true),
                                    const SizedBox(height: 14),
                                  ],
                                )).toList(),
                              ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        ),
                        error: (e, _) => Text('Error: $e'),
                      ),

                      const SizedBox(height: 20),

                      _SectionHeader(title: 'Upcoming Classes'),
                      const SizedBox(height: 14),
                      upcomingSessions.when(
                        data: (sessions) => sessions.isEmpty
                            ? _buildEmptyState('No upcoming sessions scheduled.')
                            : Column(
                                children: sessions.map((s) => Column(
                                  children: [
                                    _sessionCard(context, ref, s, isLive: false),
                                    const SizedBox(height: 14),
                                  ],
                                )).toList(),
                              ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        ),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(PhosphorIconsFill.calendarBlank, size: 28, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(
    BuildContext context,
    WidgetRef ref,
    dynamic session, {
    required bool isLive,
  }) {
    final title = session.topic;
    final sessionCode = session.joinCode;
    final time = isLive ? 'Live Now' : 'Scheduled';

    if (isLive) {
      // Active/live card — warm gradient fill
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.activeCardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.ambientShadowWarm,
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              session.subject.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Code: $sessionCode',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/join/$sessionCode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                child: const Text(
                  'Join Live Course',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Upcoming card — white card
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    time,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Code: $sessionCode',
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              session.subject.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: AppTheme.titleLarge),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _showReminderDialog(context, ref, title),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                child: const Text(
                  'Remind Me',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _remedialCard(BuildContext context, RemedialAssignment assignment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.activeCardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.ambientShadowWarm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsFill.lightning, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Recommended For You',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Personalized Quiz',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your recent performance. Focused on: ${assignment.weaknessesTargeted.join(', ')}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.go('/quiz', extra: assignment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              child: const Text(
                'Start Quiz Now',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTheme.titleLarge);
  }
}
