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
    required String response,
    String? detailText,
  }) async {
    final data = await _client.from('student_responses').insert({
      'question_id': questionId,
      'student_id': studentId,
      'session_id': sessionId,
      'response': response,
      'detail_text': detailText,
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

  /// Get Leaderboard (scores based on correct answers)
  Future<List<Map<String, dynamic>>> getLeaderboard(String sessionId) async {
    // We join student_responses with questions to check if sr.response == q.correct_option
    // and join with session_students to get the name
    final response = await _client
        .from('student_responses')
        .select('''
          student_id,
          session_students!inner (student_name),
          questions!inner (correct_option),
          response
        ''')
        .eq('session_id', sessionId);

    // Calculate scores locally for now to handle complex matching logic if needed
    final scores = <String, Map<String, dynamic>>{};

    for (final row in response as List) {
      final studentId = row['student_id'] as String;
      final studentName = row['session_students']['student_name'] as String;
      final correctOption = row['questions']['correct_option'] as String?;
      final studentResponse = row['response'] as String;

      if (!scores.containsKey(studentId)) {
        scores[studentId] = {
          'name': studentName,
          'score': 0,
        };
      }

      if (correctOption != null && studentResponse == correctOption) {
        scores[studentId]!['score'] = (scores[studentId]!['score'] as int) + 100; // 100 pts per correct answer
      }
    }

    // Convert to list, sort by score desc
    final leaderboard = scores.values.toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return leaderboard;
  }
}
