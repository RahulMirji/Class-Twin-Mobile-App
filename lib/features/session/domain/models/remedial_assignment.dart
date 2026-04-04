class RemedialAssignment {
  final String id;
  final String studentName;
  final List<String> weaknessesTargeted;
  final QuizContent quizContent;
  final List<Map<String, dynamic>>? studentResponses;
  final String status;
  final int score;
  final DateTime createdAt;

  RemedialAssignment({
    required this.id,
    required this.studentName,
    required this.weaknessesTargeted,
    required this.quizContent,
    this.studentResponses,
    required this.status,
    required this.score,
    required this.createdAt,
  });

  factory RemedialAssignment.fromJson(Map<String, dynamic> json) {
    return RemedialAssignment(
      id: json['id'] as String,
      studentName: json['student_name'] as String,
      weaknessesTargeted: (json['weaknesses_targeted'] as List? ?? []).cast<String>(),
      quizContent: QuizContent.fromJson(json['quiz_content'] as Map<String, dynamic>),
      studentResponses: (json['student_responses'] as List?)?.cast<Map<String, dynamic>>(),
      status: json['status'] as String? ?? 'pending',
      score: json['score'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class QuizContent {
  final List<QuizQuestion> questions;

  QuizContent({required this.questions});

  factory QuizContent.fromJson(Map<String, dynamic> json) {
    return QuizContent(
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final String correctOption;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOption,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String,
      options: (json['options'] as List).cast<String>(),
      correctOption: json['correct_option'] as String,
    );
  }
}
