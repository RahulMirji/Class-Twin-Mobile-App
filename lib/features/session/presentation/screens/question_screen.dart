import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme.dart';
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
          detailText: _showDetail ? _detailController.text.trim() : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);

    if (sessionState is! SessionQuestion) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final questionState = sessionState;
    final question = questionState.question;
    final timeRemaining = questionState.timeRemaining;
    final timeFraction = timeRemaining.inSeconds / question.timeLimitSeconds;

    final options = question.options;

    // Timer color
    final timerColor = timeFraction > 0.5
        ? AppTheme.tertiary
        : timeFraction > 0.25
            ? AppTheme.responseSomewhat
            : AppTheme.error;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Timer bar — thicker, amber→red
            SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: timeFraction.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceContainerLow,
                color: timerColor,
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
                            const SizedBox(height: 32),

                            // Time remaining chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: timerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: timerColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${timeRemaining.inSeconds}s remaining',
                                    style: AppTheme.labelSmall.copyWith(
                                      color: timerColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Question text — editorial serif
                            Text(
                              question.questionText,
                              style: AppTheme.displayMedium,
                            ).animate().fadeIn(duration: 500.ms),

                            const Spacer(),

                            const SizedBox(height: 28),

                            // Response options (MCQ)
                            ...options.asMap().entries.map((entry) {
                              final index = entry.key;
                              final optionText = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ResponseOptionTile(
                                  label: optionText,
                                  onTap: () => _submitResponse(optionText),
                                ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms),
                              );
                            }),

                            const SizedBox(height: 8),

                            // Add detail
                            Center(
                              child: TextButton(
                                onPressed: () => setState(() => _showDetail = !_showDetail),
                                child: Text(
                                  _showDetail ? 'Hide detail' : 'Add detail',
                                  style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                                ),
                              ),
                            ),

                            if (_showDetail)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextField(
                                  controller: _detailController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'What specifically was unclear?',
                                    filled: true,
                                    fillColor: AppTheme.surfaceContainerLow,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.08),

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

class _ResponseOptionTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ResponseOptionTile({
    required this.label,
    required this.onTap,
  });

  @override
  State<_ResponseOptionTile> createState() => _ResponseOptionTileState();
}

class _ResponseOptionTileState extends State<_ResponseOptionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _isPressed ? AppTheme.primaryContainer : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: _isPressed ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.6),
            width: _isPressed ? 1.5 : 1,
          ),
          boxShadow: _isPressed ? AppTheme.ambientShadowWarm : AppTheme.cardShadow,
        ),
        child: Text(
          widget.label,
          style: AppTheme.titleMedium.copyWith(
            color: _isPressed ? AppTheme.primary : AppTheme.textPrimary,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
