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

  bool _hasCheckedAnswer = false;
  String? _explanation;
  bool _isFetchingExplanation = false;

  void _onOptionSelected(String option) {
    if (_hasCheckedAnswer) return;
    setState(() {
      _answers[_currentQuestionIndex] = option;
    });
  }

  Future<void> _checkAnswer() async {
    final questions = widget.assignment.quizContent.questions;
    final currentQuestion = questions[_currentQuestionIndex];
    final answer = _answers[_currentQuestionIndex];
    
    if (answer == null) return;

    setState(() {
      _hasCheckedAnswer = true;
      _isFetchingExplanation = true;
      _explanation = null;
    });

    final explanation = await ref.read(assignmentsRepositoryProvider).fetchQuizExplanation(
      question: currentQuestion.text,
      correctOption: currentQuestion.correctOption,
      studentAnswer: answer,
    );

    if (mounted) {
      setState(() {
        _explanation = explanation ?? "The correct answer is ${currentQuestion.correctOption}.";
        _isFetchingExplanation = false;
      });
    }
  }

  void _nextQuestion(dynamic tr) {
    if (_currentQuestionIndex < widget.assignment.quizContent.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _hasCheckedAnswer = false;
        _explanation = null;
        _isFetchingExplanation = false;
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
                    final isCorrectOption = option == currentQuestion.correctOption;
                    
                    Color bgColor = isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow;
                    Color borderColor = isSelected ? AppTheme.primary : AppTheme.surfaceContainerHighest;
                    Color iconColor = isSelected ? AppTheme.primary : AppTheme.textTertiary;
                    IconData? iconData = isSelected ? Icons.check : null;
                    Color iconIconColor = Colors.white;

                    if (_hasCheckedAnswer) {
                      if (isCorrectOption) {
                        bgColor = Colors.green.withValues(alpha: 0.1);
                        borderColor = Colors.green;
                        iconColor = Colors.green;
                        iconData = Icons.check;
                      } else if (isSelected) {
                        bgColor = Colors.red.withValues(alpha: 0.1);
                        borderColor = Colors.red;
                        iconColor = Colors.red;
                        iconData = Icons.close;
                      } else {
                        borderColor = AppTheme.surfaceContainerHighest.withValues(alpha: 0.5);
                        iconColor = AppTheme.textTertiary.withValues(alpha: 0.5);
                      }
                    }

                    return GestureDetector(
                      onTap: () => _onOptionSelected(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: iconColor, width: 2),
                                color: (isSelected && !_hasCheckedAnswer) || (_hasCheckedAnswer && (isCorrectOption || isSelected)) ? iconColor : Colors.transparent,
                              ),
                              child: iconData != null && ((isSelected && !_hasCheckedAnswer) || (_hasCheckedAnswer && (isCorrectOption || isSelected)))
                                  ? Icon(iconData, size: 16, color: iconIconColor)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: (_hasCheckedAnswer && (isCorrectOption || isSelected)) ? iconColor : AppTheme.textPrimary,
                                  fontWeight: (isSelected || (_hasCheckedAnswer && isCorrectOption)) ? FontWeight.bold : FontWeight.normal,
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
              if (_hasCheckedAnswer) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PhosphorIconsFill.sparkle, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('AI Explanation', style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isFetchingExplanation)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_explanation != null)
                        Text(
                          _explanation!,
                          style: AppTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _answers.containsKey(_currentQuestionIndex) && !_isSubmitting && (!_hasCheckedAnswer || !_isFetchingExplanation)
                      ? (_hasCheckedAnswer ? () => _nextQuestion(tr) : _checkAnswer)
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          !_hasCheckedAnswer 
                            ? 'Check Answer' 
                            : (_currentQuestionIndex == questions.length - 1 ? tr.get('submit_quiz') : tr.get('next_question')),
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
