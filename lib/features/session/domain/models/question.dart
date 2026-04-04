/// Question model — a comprehension check question from the teacher
class Question {
  final String id;
  final String sessionId;
  final int roundNumber;
  final String questionText;
  final int timeLimitSeconds;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.questionText,
    required this.timeLimitSeconds,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      roundNumber: json['round_number'] as int,
      questionText: json['question_text'] as String,
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 30,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
