import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';

/// Demo Gallery — navigate all screens in UI preview mode
class DemoGallery extends StatelessWidget {
  const DemoGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DemoItem(
        icon: PhosphorIconsBold.house,
        title: 'Home Screen',
        subtitle: 'Session code entry',
        route: '/',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.userPlus,
        title: 'Join Screen',
        subtitle: 'Name + mode selection (2-step)',
        route: '/join/DEMO01',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.hourglassMedium,
        title: 'Lobby Screen',
        subtitle: 'Waiting for session to start',
        route: '/session/lobby',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.question,
        title: 'Question Screen',
        subtitle: 'Comprehension check response',
        route: '/session/question',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.clock,
        title: 'Waiting Screen',
        subtitle: 'Between questions',
        route: '/session/waiting',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.broadcast,
        title: 'Stream Screen',
        subtitle: 'Full-screen remote mode with PiP',
        route: '/session/stream',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.prohibit,
        title: 'Stream Ended',
        subtitle: 'Teacher stopped broadcast',
        route: '/session/stream-ended',
      ),
      _DemoItem(
        icon: PhosphorIconsBold.checkCircle,
        title: 'Session End',
        subtitle: 'Session complete summary',
        route: '/session/ended',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ClassTwin',
                    style: AppTheme.displayLarge.copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      'UI PREVIEW MODE',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.tertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap any screen to preview it. No backend connection required.',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: screens.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = screens[index];
                  return _ScreenCard(item: item, index: index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _DemoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class _ScreenCard extends StatelessWidget {
  final _DemoItem item;
  final int index;

  const _ScreenCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(item.icon, size: 20, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
        );
  }
}
