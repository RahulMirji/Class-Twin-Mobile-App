import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:class_twin/features/stream/domain/models/chat_message.dart';

/// Chat repository — Supabase CRUD and Realtime for chat messages
class ChatRepository {
  final SupabaseClient _client;

  ChatRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch existing chat messages for a session
  Future<List<ChatMessage>> fetchMessages(String sessionId) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('sent_at', ascending: true);

    return (response as List)
        .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Send a chat message
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String studentId,
    required String studentName,
    required String messageText,
    required bool isAnonymous,
  }) async {
    final displayName = isAnonymous ? 'Anonymous' : studentName;

    final response = await _client.from('chat_messages').insert({
      'session_id': sessionId,
      'student_id': studentId,
      'student_name': displayName,
      'message_text': messageText,
      'is_anonymous': isAnonymous,
    }).select().single();

    return ChatMessage.fromJson(response);
  }

  /// Subscribe to new chat messages via Realtime
  RealtimeChannel subscribeToMessages(
    String sessionId, {
    required void Function(ChatMessage message) onMessage,
  }) {
    return _client
        .channel('chat:$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            final message = ChatMessage.fromJson(payload.newRecord);
            onMessage(message);
          },
        )
        .subscribe();
  }
}
