import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/chat_message.dart';

/// Persists chat messages locally using Hive.
///
/// Messages are stored as JSON-encoded strings in a Hive box,
/// keyed by a single entry ('messages'). This avoids needing
/// a custom TypeAdapter while keeping the persistence layer clean.
class ChatStorageService {
  static const String _boxName = 'ai_chatbot';
  static const String _messagesKey = 'messages';

  Box? _box;

  /// Open the Hive box. Safe to call multiple times.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
  }

  /// Load all persisted messages, ordered by timestamp.
  Future<List<ChatMessage>> loadMessages() async {
    await init();
    final raw = _box?.get(_messagesKey) as String?;
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final messages = decoded
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (_) {
      // Corrupted data — wipe and start fresh
      await clearMessages();
      return [];
    }
  }

  /// Persist the full message list (overwrites previous state).
  Future<void> saveMessages(List<ChatMessage> messages) async {
    await init();
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _box?.put(_messagesKey, encoded);
  }

  /// Clear all stored messages.
  Future<void> clearMessages() async {
    await init();
    await _box?.delete(_messagesKey);
  }
}
