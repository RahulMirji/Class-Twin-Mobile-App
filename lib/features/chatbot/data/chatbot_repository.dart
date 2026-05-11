import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/chat_message.dart';

/// Communicates with the `ai-doubt-solver` Supabase Edge Function
/// to get AI responses for student doubts.
///
/// The edge function handles:
/// - Calling the Gemini API with the student's question
/// - Maintaining conversation context via the message history
/// - Language detection and native-language response
class ChatbotRepository {
  final _client = Supabase.instance.client;

  /// Send a doubt to the AI tutor and return the response text.
  ///
  /// [question] is the student's message in any language.
  /// [history] provides conversation context (last N messages).
  ///
  /// Throws [ChatbotException] on failure.
  Future<String> askDoubt({
    required String question,
    required List<ChatMessage> history,
  }) async {
    try {
      // Send last 10 messages for context (keeps payload small)
      final contextMessages = history
          .where((m) => m.status != MessageStatus.error)
          .toList();
      final recentHistory = contextMessages.length > 10
          ? contextMessages.sublist(contextMessages.length - 10)
          : contextMessages;

      final response = await _client.functions.invoke(
        'ai-doubt-solver',
        body: {
          'question': question,
          'history': recentHistory
              .map((m) => {
                    'role': m.isUser ? 'user' : 'model',
                    'text': m.text,
                  })
              .toList(),
        },
      );

      if (response.status != 200) {
        throw ChatbotException(
          'AI service returned status ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final answer = data['answer'] as String?;

      if (answer == null || answer.isEmpty) {
        throw const ChatbotException('Empty response from AI');
      }

      return answer;
    } on FunctionException catch (e) {
      throw ChatbotException(
        e.details?.toString() ?? 'Failed to reach AI service',
      );
    } catch (e) {
      if (e is ChatbotException) rethrow;
      throw ChatbotException('Something went wrong: $e');
    }
  }
}

/// Domain-specific exception for chatbot errors.
class ChatbotException implements Exception {
  final String message;
  const ChatbotException(this.message);

  @override
  String toString() => 'ChatbotException: $message';
}
