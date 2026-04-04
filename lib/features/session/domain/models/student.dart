/// Student model — a participant in a session
class Student {
  final String id;
  final String sessionId;
  final String studentName;
  final String? deviceId;
  final StudentMode mode;
  final DateTime joinedAt;
  final int manualConfidence;

  const Student({
    required this.id,
    required this.sessionId,
    required this.studentName,
    this.deviceId,
    required this.mode,
    required this.joinedAt,
    this.manualConfidence = 50,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      studentName: json['student_name'] as String,
      deviceId: json['device_id'] as String?,
      mode: StudentMode.fromString(json['mode'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      manualConfidence: (json['manual_confidence'] as num?)?.toInt() ?? 50,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'session_id': sessionId,
      'student_name': studentName,
      'device_id': deviceId,
      'mode': mode.name,
    };
  }
}

enum StudentMode {
  inRoom('in_room'),
  remote('remote');

  final String value;
  const StudentMode(this.value);

  static StudentMode fromString(String value) {
    if (value == 'remote') return StudentMode.remote;
    return StudentMode.inRoom;
  }

  @override
  String toString() => value;
}
