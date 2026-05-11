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
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  report.studentName,
                                  style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    date,
                                    style: AppTheme.labelMedium.copyWith(color: AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            
                            // Dynamically render the report_data
                            ...report.reportData.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatKey(entry.key),
                                      style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.value.toString(),
                                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
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

  String _formatKey(String key) {
    return key.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }
}
