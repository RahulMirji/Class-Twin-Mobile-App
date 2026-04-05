/// Chat message model
class ChatMessage {
  final String id;
  final String sessionId;
  final String? studentId;
  final String studentName;
  final String messageText;
  final bool isAnonymous;
  final bool isTeacher;
  final DateTime sentAt;
  final ChatMessageStatus status;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    this.studentId,
    required this.studentName,
    required this.messageText,
    this.isAnonymous = false,
    this.isTeacher = false,
    required this.sentAt,
    this.status = ChatMessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String? ?? 
          (json['is_teacher'] == true ? 'Teacher' : 'Unknown'),
      messageText: json['message_text'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isTeacher: json['is_teacher'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  factory ChatMessage.fromPayload(Map<String, dynamic> json) {
    return ChatMessage.fromJson(json);
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'session_id': sessionId,
      'student_id': studentId,
      'student_name': isAnonymous ? 'Anonymous' : studentName,
      'message_text': messageText,
      'is_anonymous': isAnonymous,
      'is_teacher': isTeacher,
    };
  }

  ChatMessage copyWith({ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      studentId: studentId,
      studentName: studentName,
      messageText: messageText,
      isAnonymous: isAnonymous,
      isTeacher: isTeacher,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }
}

enum ChatMessageStatus { pending, sent, failed }
