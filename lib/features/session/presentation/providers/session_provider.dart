import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../../domain/models/session.dart';
import '../../domain/models/student.dart';
import '../../domain/models/question.dart';
// import '../../domain/models/student_response.dart';
import '../../domain/session_state.dart';
import '../../data/session_repository.dart';

// ─── Repository Provider ──────────────────────────────────────
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

// ─── Student Mode ─────────────────────────────────────────────
final studentModeProvider =
    StateProvider<StudentMode>((ref) => StudentMode.inRoom);

// ─── Current Student ──────────────────────────────────────────
final currentStudentProvider = StateProvider<Student?>((ref) => null);

// ─── Current Session ID ───────────────────────────────────────
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

// ─── Session State Provider ───────────────────────────────────
final sessionStateProvider =
    StateNotifierProvider<SessionStateNotifier, SessionState>((ref) {
  return SessionStateNotifier(ref);
});

class SessionStateNotifier extends StateNotifier<SessionState> {
  final Ref _ref;
  RealtimeChannel? _channel;
  Timer? _timer;

  SessionStateNotifier(this._ref) : super(const SessionInitial());

  SessionRepository get _repo => _ref.read(sessionRepositoryProvider);

  /// Join a session by code
  Future<void> joinSession({
    required String joinCode,
    required String studentName,
    required StudentMode mode,
  }) async {
    state = const SessionLoading();

    try {
      // 1. Find session
      final session = await _repo.findByJoinCode(joinCode);
      if (session == null) {
        state = const SessionError('Session not found. Check your code.');
        return;
      }

      // 2. Join as student
      final student = await _repo.joinSession(
        sessionId: session.id,
        studentName: studentName,
        mode: mode,
      );

      _ref.read(currentStudentProvider.notifier).state = student;
      _ref.read(currentSessionIdProvider.notifier).state = session.id;
      _ref.read(studentModeProvider.notifier).state = mode;

      // 3. Set initial state based on session status + mode
      if (session.status == SessionStatus.ended) {
        state = SessionEnded(session);
      } else if (mode == StudentMode.remote) {
        // Remote students always go through the streaming path
        if (session.isStreaming) {
          state = SessionStreaming(session: session);
        } else {
          state = SessionStreamPending(session);
        }
      } else if (session.status == SessionStatus.waiting) {
        state = SessionLobby(session);
      } else {
        state = SessionWaiting(
            session: session, lastRoundNumber: session.currentRound);
      }

      // 4. Subscribe to Realtime
      _subscribeToRealtime(session.id);
    } catch (e) {
      state = SessionError('Failed to join: ${e.toString()}');
    }
  }

  void _subscribeToRealtime(String sessionId) {
    _channel = Supabase.instance.client.channel('session-changes:$sessionId');

    // Listen for session row updates (status, streaming, round changes)
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) => _handleSessionChange(payload.newRecord),
        )
        // Listen for new questions being inserted
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) => _handleNewQuestion(payload.newRecord),
        )
        .subscribe();
  }

  void _handleSessionChange(Map<String, dynamic> record) async {
    final newStatus = record['status'] as String?;
    final currentRound = record['current_round'] as int? ?? 0;
    final isStreaming = record['is_streaming'] as bool? ?? false;
    final mode = _ref.read(studentModeProvider);
    final sessionId = _ref.read(currentSessionIdProvider);
    if (sessionId == null) return;

    try {
      final session = await _repo.getSession(sessionId);

      if (newStatus == 'ended') {
        _timer?.cancel();
        state = SessionEnded(session);
        return;
      }

      // Handle streaming state transitions for remote students
      if (mode == StudentMode.remote) {
        if (isStreaming) {
          final currentState = state;
          if (currentState is SessionStreamPending || 
              currentState is SessionLobby ||
              currentState is SessionWaiting) {
            // Stream started — transition to streaming (no question yet)
            state = SessionStreaming(session: session);
          }

          // If a new round has started, overlay the question
          if (newStatus == 'active' && currentRound > 0) {
            final question = await _repo.getQuestionForRound(sessionId, currentRound);
            if (question != null) {
              state = SessionStreaming(
                session: session,
                currentQuestion: question,
                roundNumber: currentRound,
              );
            }
          }

          // If already streaming, keep them in streaming state
          if (currentState is SessionStreaming && newStatus == 'active') {
            // Don't change state — they're already watching
            return;
          }
        } else {
          // Stream stopped
          final currentState = state;
          if (currentState is SessionStreaming) {
            state = SessionStreamPending(session);
          }
        }
        return;
      }

      // ─── In-room students (non-remote) ─────────────────────
      if (newStatus == 'active' && currentRound > 0) {
        // A new round has started — fetch the question
        final question = await _repo.getQuestionForRound(sessionId, currentRound);
        if (question != null) {
          state = SessionQuestion(
            session: session,
            question: question,
            roundNumber: currentRound,
            timeRemaining: Duration(seconds: question.timeLimitSeconds),
          );
          _startTimer(question.timeLimitSeconds);
        }
      } else if (newStatus == 'active') {
        // Session started but no question yet
        final currentState = state;
        if (currentState is SessionLobby || currentState is SessionStreamPending) {
          state = SessionWaiting(session: session, lastRoundNumber: 0);
        }
      }
    } catch (_) {}
  }

  void _handleNewQuestion(Map<String, dynamic> record) async {
    // Alternative path — react to question inserts
    final sessionId = _ref.read(currentSessionIdProvider);
    if (sessionId == null) return;
    final roundNumber = record['round_number'] as int? ?? 1;
    
    try {
      final session = await _repo.getSession(sessionId);
      final question = await _repo.getQuestionForRound(sessionId, roundNumber);
      if (question == null) return;
      
      final mode = _ref.read(studentModeProvider);
      if (mode == StudentMode.remote) {
        state = SessionStreaming(
          session: session,
          currentQuestion: question,
          roundNumber: roundNumber,
        );
      } else {
        state = SessionQuestion(
          session: session,
          question: question,
          roundNumber: roundNumber,
          timeRemaining: Duration(seconds: question.timeLimitSeconds),
        );
        _startTimer(question.timeLimitSeconds);
      }
    } catch (_) {}
  }

/*
  void _handleSessionStarted(Map<String, dynamic> payload) {
    ...
  }
*/

/*
  void _handleNextQuestion(Map<String, dynamic> payload) async {
    ...
  }
*/

  void _startTimer(int seconds) {
    _timer?.cancel();
    var remaining = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      final currentState = state;
      if (currentState is SessionQuestion) {
        state = currentState.copyWith(
          timeRemaining: Duration(seconds: remaining),
        );
      }
      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

/*
  void _handleSessionEnded(Map<String, dynamic> payload) async {
    ...
  }

  void _handleResult(Map<String, dynamic> payload) {
    // Results can be handled here if needed
  }
*/

/*
  void _handleStreamStarted(Map<String, dynamic> payload) {
    ...
  }

  void _handleStreamEnded(Map<String, dynamic> payload) {
    ...
  }
*/

  /// Submit a response to the current question
  Future<void> submitResponse(String response,
      {String? detailText}) async {
    final student = _ref.read(currentStudentProvider);
    if (student == null) return;

    final currentState = state;
    Question? question;
    Session? session;

    if (currentState is SessionQuestion) {
      question = currentState.question;
      session = currentState.session;
    } else if (currentState is SessionStreaming) {
      question = currentState.currentQuestion;
      session = currentState.session;
    }

    if (question == null || session == null) return;

    try {
      final submitted = await _repo.submitResponse(
        questionId: question.id,
        studentId: student.id,
        sessionId: session.id,
        response: response,
        detailText: detailText,
      );

      if (currentState is SessionQuestion) {
        _timer?.cancel();
        state = SessionWaiting(
          session: session,
          lastRoundNumber: currentState.roundNumber,
          lastResponse: submitted,
        );
      } else if (currentState is SessionStreaming) {
        state = currentState.copyWith(submittedResponse: submitted);
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Leave session
  void leaveSession() {
    _timer?.cancel();
    _channel?.unsubscribe();
    _channel = null;
    _ref.read(currentStudentProvider.notifier).state = null;
    _ref.read(currentSessionIdProvider.notifier).state = null;
    state = const SessionInitial();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}
