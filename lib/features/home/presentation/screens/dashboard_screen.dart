import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/preferences_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/notification_provider.dart';

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
    ).animate().scale(duration: 300.ms, curve: Curves.backOut).fadeIn();

    // Schedule a "demo" notification in 5 seconds
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
                    Text(
                      'Welcome Back, $studentName!',
                      style: AppTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check out your active classes and connect instantly.',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Active Classes',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _mockClassCard(
                      context,
                      ref,
                      title: 'Introduction to Physics',
                      teacher: 'Prof. Anderson',
                      time: 'Live Now',
                      sessionCode: 'PHY101',
                      isLive: true,
                    ),
                    const SizedBox(height: 16),
                    _mockClassCard(
                      context,
                      ref,
                      title: 'Advanced Calculus',
                      teacher: 'Dr. Smith',
                      time: 'Starting in 10 mins',
                      sessionCode: 'CALC201',
                      isLive: false,
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

  Widget _mockClassCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String teacher,
    required String time,
    required String sessionCode,
    required bool isLive,
  }) {
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
          Text(teacher, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
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
