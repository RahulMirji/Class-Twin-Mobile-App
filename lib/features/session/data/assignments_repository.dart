import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/remedial_assignment.dart';

class AssignmentsRepository {
  final SupabaseClient _client;

  AssignmentsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch assigned quizzes for a specific student name
  Future<List<RemedialAssignment>> fetchAssignedQuizzes(String studentName) async {
    try {
      final response = await _client
          .from('remedial_assignments')
          .select('*')
          .eq('student_name', studentName)
          .eq('status', 'assigned')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RemedialAssignment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('AssignmentsRepo: Error fetching quizzes: $e');
      return [];
    }
  }

  /// Submit quiz results
  Future<void> submitQuiz({
    required String assignmentId,
    required int score,
    required List<Map<String, dynamic>> responses,
  }) async {
    try {
      await _client.from('remedial_assignments').update({
        'status': 'completed',
        'score': score,
        'student_responses': responses,
      }).eq('id', assignmentId);
      log('AssignmentsRepo: Quiz submitted successfully');
    } catch (e) {
      log('AssignmentsRepo: Error submitting quiz: $e');
      throw Exception('Failed to submit quiz');
    }
  }

  /// Fetch an AI-generated explanation for a quiz question
  Future<String?> fetchQuizExplanation({
    required String question,
    required String correctOption,
    required String studentAnswer,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ai-quiz-explanation',
        body: {
          'question': question,
          'correctOption': correctOption,
          'studentAnswer': studentAnswer,
        },
      );
      
      if (response.status == 200 && response.data != null) {
        return response.data['explanation'] as String?;
      }
      return null;
    } catch (e) {
      log('AssignmentsRepo: Error fetching explanation: $e');
      return null;
    }
  }
}
