import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../../../core/demo_data.dart';
import '../../domain/models/student_response.dart';
import '../../domain/session_state.dart';
import '../providers/session_provider.dart';

/// QuestionScreen — Comprehension check response
class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  bool _showDetail = false;
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _submitResponse(ResponseType type) {
    ref.read(sessionStateProvider.notifier).submitResponse(
          type,
          detailText:
              _showDetail ? _detailController.text.trim() : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);

    // Demo mode fallback
    final questionState = sessionState is SessionQuestion
        ? sessionState
        : DemoData.questionState;

    final question = questionState.question;
    final timeRemaining = questionState.timeRemaining;
    final timeFraction = timeRemaining.inSeconds / question.timeLimitSeconds;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Timer bar
            SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: timeFraction.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceContainer,
                color: timeFraction > 0.3
                    ? AppTheme.tertiary
                    : AppTheme.error,
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // Time remaining
                    Text(
                      '${timeRemaining.inSeconds}s',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Question text — editorial serif
                    Text(
                      question.questionText,
                      style: AppTheme.displayMedium,
                    ).animate().fadeIn(duration: 500.ms),

                    const Spacer(),

                    // Response buttons
                    _ResponseButton(
                      label: 'Got it',
                      icon: PhosphorIconsBold.checkCircle,
                      color: AppTheme.responseGotIt,
                      onTap: () => _submitResponse(ResponseType.gotIt),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 10),

                    _ResponseButton(
                      label: 'Somewhat',
                      icon: PhosphorIconsBold.minusCircle,
                      color: AppTheme.responseSomewhat,
                      onTap: () => _submitResponse(ResponseType.somewhat),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 10),

                    _ResponseButton(
                      label: 'Lost',
                      icon: PhosphorIconsBold.xCircle,
                      color: AppTheme.responseLost,
                      onTap: () => _submitResponse(ResponseType.lost),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // Add detail link
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _showDetail = !_showDetail),
                        child: Text(
                          _showDetail ? 'Hide detail' : 'Add detail',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.tertiary,
                          ),
                        ),
                      ),
                    ),

                    if (_showDetail)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: _detailController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'What specifically was unclear?',
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ResponseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTheme.titleMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
