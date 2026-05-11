import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/chat_message.dart';
import '../../data/chatbot_repository.dart';
import '../../data/chat_storage_service.dart';

// ─── Service Providers ─────────────────────────────────────────────

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository();
});

final chatStorageServiceProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService();
});

// ─── State Providers ───────────────────────────────────────────────

/// Whether the AI is currently generating a response.
final chatLoadingProvider = StateProvider<bool>((ref) => false);

/// The main conversation state — holds all chat messages.
final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  final repository = ref.watch(chatbotRepositoryProvider);
  final storage = ref.watch(chatStorageServiceProvider);
  return ChatNotifier(repository: repository, storage: storage);
});

// ─── Chat Notifier ─────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatbotRepository repository;
  final ChatStorageService storage;
  final _uuid = const Uuid();

  ChatNotifier({
    required this.repository,
    required this.storage,
  }) : super(const AsyncValue.loading()) {
    _loadPersistedMessages();
  }

  /// Load messages from Hive on initialization.
  Future<void> _loadPersistedMessages() async {
    try {
      final messages = await storage.loadMessages();
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  List<ChatMessage> get _messages => state.valueOrNull ?? [];

  /// Send a new doubt to the AI tutor.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add the user's message immediately (optimistic)
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    final updatedMessages = [..._messages, userMessage];
    state = AsyncValue.data(updatedMessages);
    await _persist(updatedMessages);

    // 2. Add a placeholder AI message in "sending" state
    final aiPlaceholder = ChatMessage(
      id: _uuid.v4(),
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    final withPlaceholder = [...updatedMessages, aiPlaceholder];
    state = AsyncValue.data(withPlaceholder);

    // 3. Call the AI
    try {
      final answer = await repository.askDoubt(
        question: text.trim(),
        history: updatedMessages,
      );

      // Replace placeholder with actual response
      final aiResponse = aiPlaceholder.copyWith(
        text: answer,
        status: MessageStatus.sent,
      );

      final finalMessages = [...updatedMessages, aiResponse];
      state = AsyncValue.data(finalMessages);
      await _persist(finalMessages);
    } catch (e) {
      // Replace placeholder with error state
      final errorMessage = aiPlaceholder.copyWith(
        text: 'Failed to get a response. Tap to retry.',
        status: MessageStatus.error,
      );

      final withError = [...updatedMessages, errorMessage];
      state = AsyncValue.data(withError);
      await _persist(withError);
    }
  }

  /// Retry a failed message — resends the user's question that preceded it.
  Future<void> retryMessage(String failedMessageId) async {
    final messages = _messages;
    final failedIndex = messages.indexWhere((m) => m.id == failedMessageId);
    if (failedIndex < 0) return;

    // Find the user message that preceded this failed AI response
    String? userQuestion;
    for (int i = failedIndex - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        userQuestion = messages[i].text;
        break;
      }
    }
    if (userQuestion == null) return;

    // Remove the failed message
    final cleaned = messages.where((m) => m.id != failedMessageId).toList();
    state = AsyncValue.data(cleaned);

    // Resend
    await sendMessage(userQuestion);
  }

  /// Clear the entire conversation history.
  Future<void> clearConversation() async {
    state = const AsyncValue.data([]);
    await storage.clearMessages();
  }

  Future<void> _persist(List<ChatMessage> messages) async {
    // Only persist non-placeholder messages (sent or error, not sending)
    final persistable =
        messages.where((m) => m.status != MessageStatus.sending).toList();
    await storage.saveMessages(persistable);
  }
}
