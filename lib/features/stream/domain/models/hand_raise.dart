/// Hand raise model — tracks per-round hand raises
class HandRaise {
  final String id;
  final String sessionId;
  final String studentId;
  final int roundNumber;
  final DateTime raisedAt;
  final DateTime? loweredAt;

  const HandRaise({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.roundNumber,
    required this.raisedAt,
    this.loweredAt,
  });

  bool get isRaised => loweredAt == null;

  factory HandRaise.fromJson(Map<String, dynamic> json) {
    return HandRaise(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      studentId: json['student_id'] as String,
      roundNumber: json['round_number'] as int,
      raisedAt: DateTime.parse(json['raised_at'] as String),
      loweredAt: json['lowered_at'] != null
          ? DateTime.parse(json['lowered_at'] as String)
          : null,
    );
  }
}
