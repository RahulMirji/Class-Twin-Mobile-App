import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';

import 'package:class_twin/features/session/presentation/providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Live Leaderboard'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowClockwise),
            onPressed: () => ref.invalidate(leaderboardProvider),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (students) {

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: _buildPodium(students),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final student = students[index];
                      // We don't have the current student's name here easily without preferences
                      // but we can just show the list
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                student['name'] as String,
                                style: AppTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${student['score']} pts',
                              style: AppTheme.labelLarge.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.2);
                    },
                    childCount: students.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> students) {
    if (students.isEmpty) return const SizedBox();
    
    final first = students[0];
    final second = students.length > 1 ? students[1] : null;
    final third = students.length > 2 ? students[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          _PodiumBar(rank: 2, height: 100, name: second['name'], score: second['score'], color: AppTheme.responseSomewhat),
        const SizedBox(width: 12),
        _PodiumBar(rank: 1, height: 140, name: first['name'], score: first['score'], color: AppTheme.primary, isFirst: true),
        const SizedBox(width: 12),
        if (third != null)
          _PodiumBar(rank: 3, height: 80, name: third['name'], score: third['score'], color: AppTheme.responseLost),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }
}

class _PodiumBar extends StatelessWidget {
  final int rank;
  final double height;
  final String name;
  final int score;
  final Color color;
  final bool isFirst;

  const _PodiumBar({
    required this.rank,
    required this.height,
    required this.name,
    required this.score,
    required this.color,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Icon(PhosphorIconsFill.crown, color: Color(0xFFFFD700), size: 32),
          ),
        Text(name, style: AppTheme.labelMedium),
        Text('$score', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
            border: Border(
              top: BorderSide(color: color, width: 4),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
