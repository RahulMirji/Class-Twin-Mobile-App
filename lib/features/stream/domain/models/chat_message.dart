/// Chat message model
class ChatMessage {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String messageText;
  final bool isAnonymous;
  final DateTime sentAt;
  final ChatMessageStatus status;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.messageText,
    this.isAnonymous = false,
    required this.sentAt,
    this.status = ChatMessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      messageText: json['message_text'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'session_id': sessionId,
      'student_id': studentId,
      'student_name': isAnonymous ? 'Anonymous' : studentName,
      'message_text': messageText,
      'is_anonymous': isAnonymous,
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
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }
}

enum ChatMessageStatus { pending, sent, failed }
