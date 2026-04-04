/// Session model — represents a classroom session
class Session {
  final String id;
  final String joinCode;
  final String? topic;
  final int totalRounds;
  final int currentRound;
  final SessionStatus status;
  final String? createdBy;
  // Streaming
  final bool isStreaming;
  final String? livekitRoomName;
  final DateTime? streamStartedAt;
  final bool chatEnabled;
  final bool handRaiseEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Session({
    required this.id,
    required this.joinCode,
    this.topic,
    required this.totalRounds,
    required this.currentRound,
    required this.status,
    this.createdBy,
    this.isStreaming = false,
    this.livekitRoomName,
    this.streamStartedAt,
    this.chatEnabled = true,
    this.handRaiseEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      joinCode: json['join_code'] as String,
      topic: json['topic'] as String?,
      totalRounds: json['total_rounds'] as int? ?? 1,
      currentRound: json['current_round'] as int? ?? 0,
      status: SessionStatus.fromString(json['status'] as String),
      createdBy: json['created_by'] as String?,
      isStreaming: json['is_streaming'] as bool? ?? false,
      livekitRoomName: json['livekit_room_name'] as String?,
      streamStartedAt: json['stream_started_at'] != null
          ? DateTime.parse(json['stream_started_at'] as String)
          : null,
      chatEnabled: json['chat_enabled'] as bool? ?? true,
      handRaiseEnabled: json['hand_raise_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Session copyWith({
    int? currentRound,
    SessionStatus? status,
    bool? isStreaming,
    String? livekitRoomName,
    DateTime? streamStartedAt,
    bool? chatEnabled,
    bool? handRaiseEnabled,
  }) {
    return Session(
      id: id,
      joinCode: joinCode,
      topic: topic,
      totalRounds: totalRounds,
      currentRound: currentRound ?? this.currentRound,
      status: status ?? this.status,
      createdBy: createdBy,
      isStreaming: isStreaming ?? this.isStreaming,
      livekitRoomName: livekitRoomName ?? this.livekitRoomName,
      streamStartedAt: streamStartedAt ?? this.streamStartedAt,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      handRaiseEnabled: handRaiseEnabled ?? this.handRaiseEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

enum SessionStatus {
  waiting,
  active,
  ended;

  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionStatus.waiting,
    );
  }
}
