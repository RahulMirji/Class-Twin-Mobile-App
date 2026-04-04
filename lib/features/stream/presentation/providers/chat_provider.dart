import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../../../core/constants.dart';

// ─── Repository Provider ──────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// ─── Anonymous Mode Toggle ────────────────────────────────────
final chatAnonymousProvider = StateProvider<bool>((ref) => false);

// ─── Chat State Provider ──────────────────────────────────────
final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool canSend;
  final DateTime? lastSentAt;

  const ChatState({
    this.messages = const [],
    this.canSend = true,
    this.lastSentAt,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? canSend,
    DateTime? lastSentAt,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      canSend: canSend ?? this.canSend,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  Timer? _rateLimitTimer;

  ChatNotifier(this._ref) : super(const ChatState());

  ChatRepository get _repo => _ref.read(chatRepositoryProvider);

  /// Load existing messages for the session
  Future<void> loadMessages(String sessionId) async {
    try {
      final messages = await _repo.fetchMessages(sessionId);
      state = state.copyWith(messages: messages);

      // Subscribe to new messages
      _repo.subscribeToMessages(
        sessionId,
        onMessage: (message) {
          // Don't duplicate own messages (already optimistically added)
          final exists =
              state.messages.any((m) => m.id == message.id);
          if (!exists) {
            state = state.copyWith(
              messages: [...state.messages, message],
            );
          }
        },
      );
    } catch (e) {
      // Silently handle
    }
  }

  /// Send a message with optimistic update + rate limiting
  Future<void> sendMessage({
    required String sessionId,
    required String studentId,
    required String studentName,
    required String messageText,
  }) async {
    if (!state.canSend) return;
    if (messageText.trim().isEmpty) return;

    final isAnonymous = _ref.read(chatAnonymousProvider);
    final tempId = const Uuid().v4();

    // Optimistic insert
    final optimisticMessage = ChatMessage(
      id: tempId,
      sessionId: sessionId,
      studentId: studentId,
      studentName: isAnonymous ? 'Anonymous' : studentName,
      messageText: messageText.trim(),
      isAnonymous: isAnonymous,
      sentAt: DateTime.now(),
      status: ChatMessageStatus.pending,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMessage],
      canSend: false,
      lastSentAt: DateTime.now(),
    );

    // Start rate limit cooldown
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer(
      AppConstants.chatRateLimitDuration,
      () {
        if (mounted) {
          state = state.copyWith(canSend: true);
        }
      },
    );

    try {
      final sent = await _repo.sendMessage(
        sessionId: sessionId,
        studentId: studentId,
        studentName: studentName,
        messageText: messageText.trim(),
        isAnonymous: isAnonymous,
      );

      // Replace optimistic with real message
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) return sent;
        return m;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      // Mark as failed
      final updatedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(status: ChatMessageStatus.failed);
        }
        return m;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    }
  }

  @override
  void dispose() {
    _rateLimitTimer?.cancel();
    super.dispose();
  }
}
