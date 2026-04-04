/// StudentResponse model — a student's response to a question
class StudentResponse {
  final String id;
  final String questionId;
  final String studentId;
  final String sessionId;
  final ResponseType response;
  final String? detailText;
  final DateTime respondedAt;

  const StudentResponse({
    required this.id,
    required this.questionId,
    required this.studentId,
    required this.sessionId,
    required this.response,
    this.detailText,
    required this.respondedAt,
  });

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      studentId: json['student_id'] as String,
      sessionId: json['session_id'] as String,
      response: ResponseType.fromString(json['response'] as String),
      detailText: json['detail_text'] as String?,
      respondedAt: DateTime.parse(json['responded_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'question_id': questionId,
      'student_id': studentId,
      'session_id': sessionId,
      'response': response.value,
      if (detailText != null) 'detail_text': detailText,
    };
  }
}

enum ResponseType {
  gotIt('got_it'),
  somewhat('somewhat'),
  lost('lost');

  final String value;
  const ResponseType(this.value);

  static ResponseType fromString(String value) {
    switch (value) {
      case 'got_it':
        return ResponseType.gotIt;
      case 'somewhat':
        return ResponseType.somewhat;
      case 'lost':
        return ResponseType.lost;
      default:
        return ResponseType.gotIt;
    }
  }
}
