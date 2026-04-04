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

  void _submitResponse(String responseText) {
    ref.read(sessionStateProvider.notifier).submitResponse(
          responseText,
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
    
    // In demo mode or if options are empty, provide fallback options
    final options = question.options.isNotEmpty 
        ? question.options 
        : ['Option A', 'Option B', 'Option C'];

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
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

                            const SizedBox(height: 32),

                            // Response options (MCQ)
                            ...options.asMap().entries.map((entry) {
                              final index = entry.key;
                              final optionText = entry.value;
                              // Provide a stagger delay depending on the index
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ResponseOptionTile(
                                  label: optionText,
                                  onTap: () => _submitResponse(optionText),
                                ).animate().fadeIn(delay: (100 * index).ms, duration: 400.ms),
                              );
                            }),

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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseOptionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ResponseOptionTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          side: const BorderSide(color: AppTheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          label,
          style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
