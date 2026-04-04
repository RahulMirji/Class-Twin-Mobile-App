import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../domain/models/session.dart';
import '../domain/models/student.dart';
import '../domain/models/question.dart';
import '../domain/models/student_response.dart';

/// Session repository — handles all Supabase session operations
class SessionRepository {
  final SupabaseClient _client;

  SessionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Find a session by join code
  Future<Session?> findByJoinCode(String joinCode) async {
    final response = await _client
        .from('sessions')
        .select()
        .eq('join_code', joinCode.toUpperCase().trim())
        .maybeSingle();

    if (response == null) return null;
    return Session.fromJson(response);
  }

  /// Get session by id
  Future<Session> getSession(String sessionId) async {
    final response =
        await _client.from('sessions').select().eq('id', sessionId).single();
    return Session.fromJson(response);
  }

  /// Join a session as a student
  Future<Student> joinSession({
    required String sessionId,
    required String studentName,
    required StudentMode mode,
    String? deviceId,
  }) async {
    final response = await _client.from('session_students').insert({
      'session_id': sessionId,
      'student_name': studentName,
      'mode': mode == StudentMode.remote ? 'remote' : 'in_room',
      'device_id': deviceId,
    }).select().single();

    return Student.fromJson(response);
  }

  /// Get current question for a round
  Future<Question?> getQuestionForRound(
      String sessionId, int roundNumber) async {
    final response = await _client
        .from('questions')
        .select()
        .eq('session_id', sessionId)
        .eq('round_number', roundNumber)
        .maybeSingle();

    if (response == null) return null;
    return Question.fromJson(response);
  }

  /// Submit a response
  Future<StudentResponse> submitResponse({
    required String questionId,
    required String studentId,
    required String sessionId,
    required ResponseType response,
    String? detailText,
  }) async {
    final data = await _client.from('student_responses').insert({
      'question_id': questionId,
      'student_id': studentId,
      'session_id': sessionId,
      'response': response.value,
      if (detailText != null) 'detail_text': detailText,
    }).select().single();

    return StudentResponse.fromJson(data);
  }

  /// Delete a response (undo)
  Future<void> deleteResponse(String responseId) async {
    await _client.from('student_responses').delete().eq('id', responseId);
  }

  /// Subscribe to session changes via Realtime
  RealtimeChannel subscribeToSession(String sessionId) {
    return _client.channel('session:$sessionId');
  }
}
