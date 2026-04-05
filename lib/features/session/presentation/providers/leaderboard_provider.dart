import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:class_twin/features/session/data/session_repository.dart';
import 'package:class_twin/features/session/presentation/providers/session_provider.dart';
import 'package:class_twin/features/session/domain/session_state.dart';

final leaderboardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sessionState = ref.watch(sessionStateProvider);
  final repository = SessionRepository();
  
  String? sessionId;
  
  final currentState = sessionState;
  if (currentState is SessionLobby) {
    sessionId = currentState.session.id;
  } else if (currentState is SessionQuestion) {
    sessionId = currentState.session.id;
  } else if (currentState is SessionWaiting) {
    sessionId = currentState.session.id;
  } else if (currentState is SessionStreaming) {
    sessionId = currentState.session.id;
  }

  if (sessionId == null) return _dummyLeaderboard;

  final students = await repository.getLeaderboard(sessionId);
  final leaderboard = students.isEmpty ? _dummyLeaderboard : students;
  
  // Always sort descending by score
  final sorted = List<Map<String, dynamic>>.from(leaderboard)
    ..sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

  return sorted;
});

const _dummyLeaderboard = [
  {'name': 'Rahul Mirji', 'score': 1250},
  {'name': 'Arun Yadav', 'score': 1100},
  {'name': 'Ananya Singh', 'score': 1050},
  {'name': 'Sneha Kulkarni', 'score': 980},
  {'name': 'Amit Bhardwaj', 'score': 850},
  {'name': 'Vikram Rathore', 'score': 720},
];
