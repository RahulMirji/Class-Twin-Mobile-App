enum SessionStatus { waiting, active, ended }

class Session {
  final String id;
  final String joinCode;
  final String topic;
  final int totalRounds;
  final int currentRound;
  final SessionStatus status;
  final String? createdBy;
  final bool isStreaming;
  final String? livekitRoomName;
  final bool chatEnabled;
  final bool handRaiseEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.joinCode,
    required this.topic,
    required this.totalRounds,
    required this.currentRound,
    required this.status,
    this.createdBy,
    required this.isStreaming,
    this.livekitRoomName,
    required this.chatEnabled,
    required this.handRaiseEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      joinCode: json['join_code'],
      topic: json['topic'] ?? 'Untitled Class',
      totalRounds: json['total_rounds'] ?? 1,
      currentRound: json['current_round'] ?? 0,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.waiting,
      ),
      createdBy: json['created_by'],
      isStreaming: json['is_streaming'] ?? false,
      livekitRoomName: json['livekit_room_name'],
      chatEnabled: json['chat_enabled'] ?? true,
      handRaiseEnabled: json['hand_raise_enabled'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
    );
  }

  Session copyWith({
    String? topic,
    int? totalRounds,
    int? currentRound,
    SessionStatus? status,
    bool? isStreaming,
    String? livekitRoomName,
    bool? chatEnabled,
    bool? handRaiseEnabled,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id,
      joinCode: joinCode,
      topic: topic ?? this.topic,
      totalRounds: totalRounds ?? this.totalRounds,
      currentRound: currentRound ?? this.currentRound,
      status: status ?? this.status,
      createdBy: createdBy,
      isStreaming: isStreaming ?? this.isStreaming,
      livekitRoomName: livekitRoomName ?? this.livekitRoomName,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      handRaiseEnabled: handRaiseEnabled ?? this.handRaiseEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
