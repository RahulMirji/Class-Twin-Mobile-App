import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../providers/hand_raise_provider.dart';
import '../../../session/presentation/providers/session_provider.dart';

/// HandRaiseModal — Modal overlay for raising/lowering hand
/// PRD Section 7.5
class HandRaiseModal extends ConsumerWidget {
  const HandRaiseModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handState = ref.watch(handRaiseProvider);
    final student = ref.watch(currentStudentProvider);
    final sessionId = ref.watch(currentSessionIdProvider);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hand icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: handState.isRaised
                    ? AppTheme.responseGotIt.withValues(alpha: 0.1)
                    : AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                handState.isRaised
                    ? PhosphorIconsFill.handPalm
                    : PhosphorIconsRegular.handPalm,
                size: 36,
                color: handState.isRaised
                    ? AppTheme.responseGotIt
                    : AppTheme.textTertiary,
              ),
            )
                .animate()
                .scaleXY(
                    begin: 0.8,
                    end: 1,
                    duration: 400.ms,
                    curve: Curves.elasticOut),

            const SizedBox(height: 16),

            // Title
            Text(
              handState.isRaised ? 'Your hand is raised' : 'Raise your hand',
              style: AppTheme.titleLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              handState.isRaised
                  ? 'Waiting for your teacher to respond'
                  : 'Your teacher will see this on their dashboard',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: handState.isRaised
                  ? OutlinedButton(
                      onPressed: handState.isLoading
                          ? null
                          : () => ref
                              .read(handRaiseProvider.notifier)
                              .lowerHand(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: handState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lower Hand'),
                    )
                  : ElevatedButton(
                      onPressed: handState.isLoading ||
                              student == null ||
                              sessionId == null
                          ? null
                          : () => ref
                              .read(handRaiseProvider.notifier)
                              .raiseHand(
                                sessionId: sessionId,
                                studentId: student.id,
                                roundNumber:
                                    1, // TODO: get actual round number
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentInk,
                        foregroundColor: AppTheme.onTertiary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: handState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Raise Hand'),
                    ),
            ),

            const SizedBox(height: 12),

            // Cancel / Close
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                handState.isRaised ? 'Close' : 'Cancel',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ).animate().scaleXY(
            begin: 0.9,
            end: 1,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
