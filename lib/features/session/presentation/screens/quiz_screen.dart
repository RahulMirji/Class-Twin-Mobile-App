import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:class_twin/features/session/domain/models/remedial_assignment.dart';
import 'package:class_twin/features/session/presentation/providers/assignments_provider.dart';
import 'package:class_twin/core/theme.dart';
import '../../../../core/providers/locale_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final RemedialAssignment assignment;
  const QuizScreen({super.key, required this.assignment});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {};
  bool _isSubmitting = false;

  void _onOptionSelected(String option) {
    setState(() {
      _answers[_currentQuestionIndex] = option;
    });
  }

  void _nextQuestion(dynamic tr) {
    if (_currentQuestionIndex < widget.assignment.quizContent.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz(tr);
    }
  }

  Future<void> _submitQuiz(dynamic tr) async {
    setState(() => _isSubmitting = true);

    int correctCount = 0;
    final responses = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.assignment.quizContent.questions.length; i++) {
      final question = widget.assignment.quizContent.questions[i];
      final answer = _answers[i];
      final isCorrect = answer == question.correctOption;
      if (isCorrect) correctCount++;

      responses.add({
        'question_id': question.id,
        'answer': answer,
        'is_correct': isCorrect,
      });
    }

    final score = ((correctCount / widget.assignment.quizContent.questions.length) * 100).round();

    try {
      await ref.read(assignmentsRepositoryProvider).submitQuiz(
            assignmentId: widget.assignment.id,
            score: score,
            responses: responses,
          );
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
            title: Text(tr.get('quiz_completed')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsFill.checkCircle, color: AppTheme.primary, size: 64),
                const SizedBox(height: 16),
                Text('${tr.get('you_scored')} $score%', style: AppTheme.displayMedium),
                const SizedBox(height: 8),
                Text(tr.get('quiz_performance_sent')),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.invalidate(assignedQuizzesProvider);
                    context.go('/');
                  },
                  child: Text(tr.get('back_to_dashboard')),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr.get('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final questions = widget.assignment.quizContent.questions;
    final currentQuestion = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(tr.get('ai_remedial_quiz')),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsFill.x),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 32),
              Text(
                '${tr.get('question')} ${_currentQuestionIndex + 1} ${tr.get('of')} ${questions.length}',
                style: AppTheme.labelMedium.copyWith(color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(
                currentQuestion.text,
                style: AppTheme.displaySmall,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: currentQuestion.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = currentQuestion.options[index];
                    final isSelected = _answers[_currentQuestionIndex] == option;

                    return GestureDetector(
                      onTap: () => _onOptionSelected(option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                                  width: 2,
                                ),
                                color: isSelected ? AppTheme.primary : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: isSelected ? AppTheme.onPrimary : AppTheme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _answers.containsKey(_currentQuestionIndex) && !_isSubmitting
                      ? () => _nextQuestion(tr)
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentQuestionIndex == questions.length - 1 ? tr.get('submit_quiz') : tr.get('next_question'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
