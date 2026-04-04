import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/hand_raise.dart';

/// Hand raise repository — Supabase CRUD for hand raises
class HandRaiseRepository {
  final SupabaseClient _client;

  HandRaiseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Raise hand for a specific round
  Future<HandRaise> raiseHand({
    required String sessionId,
    required String studentId,
    required int roundNumber,
  }) async {
    final response = await _client.from('hand_raises').insert({
      'session_id': sessionId,
      'student_id': studentId,
      'round_number': roundNumber,
    }).select().single();

    return HandRaise.fromJson(response);
  }

  /// Lower hand (update lowered_at)
  Future<void> lowerHand(String handRaiseId) async {
    await _client.from('hand_raises').update({
      'lowered_at': DateTime.now().toIso8601String(),
    }).eq('id', handRaiseId);
  }

  /// Get current hand raise for a student in a round
  Future<HandRaise?> getCurrentHandRaise({
    required String sessionId,
    required String studentId,
    required int roundNumber,
  }) async {
    final response = await _client
        .from('hand_raises')
        .select()
        .eq('session_id', sessionId)
        .eq('student_id', studentId)
        .eq('round_number', roundNumber)
        .maybeSingle();

    if (response == null) return null;
    return HandRaise.fromJson(response);
  }
}
