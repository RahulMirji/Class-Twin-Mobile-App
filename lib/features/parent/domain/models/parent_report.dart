class ParentReport {
  final String id;
  final String studentName;
  final String teacherId;
  final String? email;
  final Map<String, dynamic> reportData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParentReport({
    required this.id,
    required this.studentName,
    required this.teacherId,
    this.email,
    required this.reportData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentReport.fromJson(Map<String, dynamic> json) {
    return ParentReport(
      id: json['id'] as String,
      studentName: json['student_name'] as String,
      teacherId: json['teacher_id'] as String,
      email: json['email'] as String?,
      reportData: json['report_data'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}
