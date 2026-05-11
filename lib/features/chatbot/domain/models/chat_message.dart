import 'package:flutter/foundation.dart';

/// Represents a single message in the AI doubt chatbot conversation.
///
/// Messages are either from the student ([isUser] = true) or
/// the AI tutor ([isUser] = false). Each message is timestamped
/// and optionally carries a [detectedLanguage] tag set by the AI.
@immutable
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? detectedLanguage;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.detectedLanguage,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    String? detectedLanguage,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      status: status ?? this.status,
    );
  }

  /// Serialize to JSON-compatible map for Hive storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'detectedLanguage': detectedLanguage,
        'status': status.name,
      };

  /// Deserialize from a JSON-compatible map (Hive storage).
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      detectedLanguage: json['detectedLanguage'] as String?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Delivery status of a chat message.
enum MessageStatus {
  /// Message sent and response received successfully.
  sent,

  /// Waiting for AI response.
  sending,

  /// Failed to get a response — user can retry.
  error,
}
