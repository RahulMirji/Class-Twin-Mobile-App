class PeerRecommendation {
  final String studentId;
  final String studentName;
  final String email;
  final String language;
  final int comprehension;

  const PeerRecommendation({
    required this.studentId,
    required this.studentName,
    required this.email,
    required this.language,
    required this.comprehension,
  });

  factory PeerRecommendation.fromJson(Map<String, dynamic> json) {
    return PeerRecommendation(
      studentId: json['id'] as String,
      studentName: json['student_name'] as String,
      email: json['email'] as String,
      language: json['language'] as String,
      comprehension: json['comprehension'] as int? ?? 0,
    );
  }
}
