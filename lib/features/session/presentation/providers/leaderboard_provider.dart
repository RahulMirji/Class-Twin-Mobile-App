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

  if (sessionId == null) return [];

  return repository.getLeaderboard(sessionId);
});
