import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:class_twin/core/theme.dart';
import 'package:class_twin/core/providers/auth_provider.dart';
import 'package:class_twin/core/providers/locale_provider.dart';
import 'package:class_twin/features/parent/presentation/providers/parent_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final reportsAsync = ref.watch(parentReportsProvider);
    final authState = ref.watch(authStateProvider);
    final parentName = authState.value?.name ?? 'Parent';
    final childEmail = authState.value?.childEmail ?? 'your child';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          tr.get('parent_dashboard') ?? 'Parent Dashboard',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.signOut, color: AppTheme.error),
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
              context.go('/onboarding');
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${tr.get('welcome') ?? 'Welcome'}, $parentName",
                    style: AppTheme.displaySmall.copyWith(color: AppTheme.textPrimary),
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  Text(
                    "${tr.get('viewing_reports_for') ?? 'Viewing reports for'}: $childEmail",
                    style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),
          ),
          
          reportsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text(
                  "${tr.get('error') ?? 'Error'}: $err",
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                ),
              ),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.fileText, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          tr.get('no_reports_yet') ?? 'No reports available yet.',
                          style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = reports[index];
                      final date = report.createdAt.toLocal().toString().split(' ')[0];
                      
                      final data = report.reportData;
                      final aiSummary = data['aiSummary']?.toString() ?? 'No summary available.';
                      final performance = data['performance'] as Map<String, dynamic>? ?? {};
                      final attendance = data['attendance'] as Map<String, dynamic>? ?? {};
                      final engagement = data['engagement'] as Map<String, dynamic>? ?? {};
                      final sessionBreakdown = data['sessionBreakdown'] as List<dynamic>? ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                                  border: Border(bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.1))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report.studentName,
                                          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['studentEmail']?.toString() ?? '',
                                          style: AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        date,
                                        style: AppTheme.labelMedium.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // AI Summary
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.tertiaryContainer.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(PhosphorIconsFill.sparkle, color: AppTheme.tertiary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              aiSummary,
                                              style: AppTheme.bodyMedium.copyWith(height: 1.5, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Key Metrics Grid
                                    Text(tr.get('key_metrics') ?? 'Key Metrics', style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildMetricCard(context, 'Grade', performance['grade']?.toString() ?? 'N/A', PhosphorIconsRegular.graduationCap, AppTheme.primary)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildMetricCard(context, 'Attendance', '${attendance['percentage'] ?? 0}%', PhosphorIconsRegular.calendarCheck, AppTheme.responseGotIt)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildMetricCard(context, 'Avg Score', '${performance['avgScore'] ?? 0}%', PhosphorIconsRegular.chartLineUp, AppTheme.responseSomewhat)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildMetricCard(context, 'Engagement', '${engagement['avgGaze'] ?? 0}%', PhosphorIconsRegular.eye, AppTheme.tertiary)),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Session Breakdown
                                    if (sessionBreakdown.isNotEmpty) ...[
                                      Text(tr.get('recent_sessions') ?? 'Recent Sessions', style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      ...sessionBreakdown.take(3).map((session) {
                                        final sessionMap = session as Map<String, dynamic>;
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceContainerLow,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                            border: Border.all(color: AppTheme.outlineVariant),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(sessionMap['topic']?.toString() ?? 'Session', style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                                                    const SizedBox(height: 2),
                                                    Text(sessionMap['mode']?.toString().toUpperCase() ?? 'UNKNOWN', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getRiskColor(sessionMap['risk']?.toString() ?? '').withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  (sessionMap['risk']?.toString() ?? 'UNKNOWN').replaceAll('_', ' '),
                                                  style: AppTheme.labelSmall.copyWith(
                                                    color: _getRiskColor(sessionMap['risk']?.toString() ?? ''),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
                    },
                    childCount: reports.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.labelMedium.copyWith(color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'ON_TRACK':
        return AppTheme.responseGotIt;
      case 'AT_RISK':
        return AppTheme.responseSomewhat;
      case 'CRITICAL':
        return AppTheme.responseLost;
      default:
        return AppTheme.textSecondary;
    }
  }
}
