import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:class_twin/core/theme.dart';
import 'package:class_twin/core/providers/preferences_provider.dart';
import 'package:class_twin/core/providers/notification_provider.dart';
import 'package:class_twin/core/providers/auth_provider.dart';
import 'package:class_twin/features/session/presentation/providers/session_list_provider.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentName = ref.watch(studentNameProvider) ?? 'Student';
    final activeSessions = ref.watch(activeSessionsProvider);
    final upcomingSessions = ref.watch(upcomingSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome Back, $studentName!',
                            style: AppTheme.displayMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check out your active classes and connect instantly.',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'Live Classes',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    activeSessions.when(
                      data: (sessions) => sessions.isEmpty
                          ? _buildEmptyState('No live classes at the moment.')
                          : Column(
                              children: sessions.map((s) => Column(
                                children: [
                                  _sessionCard(context, ref, s, isLive: true),
                                  const SizedBox(height: 16),
                                ],
                              )).toList(),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Upcoming Classes',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    upcomingSessions.when(
                      data: (sessions) => sessions.isEmpty
                          ? _buildEmptyState('No upcoming classes scheduled.')
                          : Column(
                              children: sessions.map((s) => Column(
                                children: [
                                  _sessionCard(context, ref, s, isLive: false),
                                  const SizedBox(height: 16),
                                ],
                              )).toList(),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        children: [
          Icon(PhosphorIconsFill.calendarBlank, size: 48, color: AppTheme.textTertiary.withValues(alpha: 0.3)),
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isLive ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isLive) ...[
                      Icon(PhosphorIconsFill.circle, size: 8, color: AppTheme.error),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      time,
                      style: AppTheme.labelSmall.copyWith(
                        color: isLive ? AppTheme.error : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
          Text(title, style: AppTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Join code: $sessionCode', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (isLive) {
                  context.go('/join/$sessionCode');
                } else {
                  _showReminderDialog(context, ref, title);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLive ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                foregroundColor: isLive ? AppTheme.onPrimary : AppTheme.textSecondary,
                elevation: 0,
              ),
              child: Text(isLive ? 'Join Live Course' : 'Remind Me'),
            ),
          )
        ],
      ),
    );
  }
}
