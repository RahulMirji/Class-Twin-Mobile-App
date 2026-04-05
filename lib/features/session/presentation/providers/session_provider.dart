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
    final client = Supabase.instance.client;
    _channel = client.channel('session-changes:$sessionId');

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
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) => _handleQuestionInsert(payload.newRecord),
        )
        .subscribe();
  }

  void _handleQuestionInsert(Map<String, dynamic> record) async {
    final sessionId = _ref.read(currentSessionIdProvider);
    if (sessionId == null) return;

    final roundNumber = record['round_number'] as int? ?? 0;
    if (roundNumber == 0) return;

    try {
      final session = await _repo.getSession(sessionId);
      final questions = await _fetchQuestionsWithRetry(sessionId, roundNumber);

      if (questions.isNotEmpty) {
        _transitionToQuestions(session, questions, roundNumber);
      }
    } catch (_) {}
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

      // ─── Quiz Synchronization (Multi-question Rounds) ──────
      if (currentRound > 0) {
        // A round is active - fetch questions with retry for replication lag
        final questions = await _fetchQuestionsWithRetry(sessionId, currentRound);
        
        if (questions.isNotEmpty) {
          // Only transition if we're not already in this specific round
          final currentState = state;
          bool alreadyInRound = false;
          if (currentState is SessionQuestion && currentState.roundNumber == currentRound) {
             alreadyInRound = true;
          }

          if (!alreadyInRound) {
            _transitionToQuestions(session, questions, currentRound);
            return;
          }
        }
      }

      // ─── Mode Specific State Transitions ───────────────────
      if (mode == StudentMode.remote) {
        final currentState = state;
        if (isStreaming) {
          if (currentState is SessionStreamPending || currentState is SessionLobby || currentState is SessionWaiting) {
            state = SessionStreaming(session: session);
          }
        } else {
          if (currentState is SessionStreaming) {
            state = SessionStreamPending(session);
          }
        }
      } else {
        // In-room students
        if (newStatus == 'active' && currentRound == 0) {
          final currentState = state;
          if (currentState is SessionLobby || currentState is SessionQuestion) {
            state = SessionWaiting(session: session, lastRoundNumber: 0);
          }
        }
      }
    } catch (_) {}
  }

  void _transitionToQuestions(
      Session session, List<Question> questions, int roundNumber) {
    final mode = _ref.read(studentModeProvider);

    // Prevent duplicate transitions if we're already on this round
    final currentState = state;
    if (currentState is SessionQuestion &&
        currentState.roundNumber == roundNumber) return;
    if (currentState is SessionStreaming &&
        currentState.roundNumber == roundNumber &&
        currentState.questions != null) return;

    if (mode == StudentMode.remote) {
      state = SessionStreaming(
        session: session,
        questions: questions,
        currentIndex: 0,
        roundNumber: roundNumber,
      );
    } else {
      final firstQuestion = questions.first;
      state = SessionQuestion(
        session: session,
        questions: questions,
        currentIndex: 0,
        roundNumber: roundNumber,
        timeRemaining: Duration(seconds: firstQuestion.timeLimitSeconds),
      );
      _startTimer(firstQuestion.timeLimitSeconds);
    }
  }

  /// Helper to fetch a question with a 3-step retry (200ms -> 500ms -> 1s)
  /// Necessary to handle Supabase Postgres -> Realtime replication lag
  /// Now fetches ALL questions for the round.
  Future<List<Question>> _fetchQuestionsWithRetry(
      String sessionId, int roundNumber) async {
    final delays = [
      const Duration(milliseconds: 200),
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 1000),
    ];

    // Try immediately
    var questions = await _repo.getQuestionsForRound(sessionId, roundNumber);
    if (questions.isNotEmpty) return questions;

    // Retry loop
    for (var i = 0; i < delays.length; i++) {
      await Future.delayed(delays[i]);
      questions = await _repo.getQuestionsForRound(sessionId, roundNumber);
      if (questions.isNotEmpty) return questions;
    }

    return [];
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
      question = currentState.currentQuestion;
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
        
        // Check if there are more questions in this round
        if (currentState.currentIndex + 1 < currentState.questions.length) {
          // Wait a second for visual feedback then move to next
          Future.delayed(const Duration(milliseconds: 1500), () {
            final nextIndex = currentState.currentIndex + 1;
            final nextQuestion = currentState.questions[nextIndex];
            state = currentState.copyWith(
              currentIndex: nextIndex,
              submittedResponse: null,
              timeRemaining: Duration(seconds: nextQuestion.timeLimitSeconds),
            );
            _startTimer(nextQuestion.timeLimitSeconds);
          });
        } else {
          // No more questions in round
          state = SessionWaiting(
            session: session,
            lastRoundNumber: currentState.roundNumber,
            lastResponse: submitted,
          );
        }
      } else if (currentState is SessionStreaming) {
        // Handle question progression for remote students
        if (currentState.questions != null &&
            currentState.currentIndex != null &&
            currentState.currentIndex! + 1 < currentState.questions!.length) {
          
          // Show submitted state briefly then move to next
          state = currentState.copyWith(submittedResponse: submitted);
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            final nextIndex = currentState.currentIndex! + 1;
            state = currentState.copyWith(
              currentIndex: nextIndex,
              submittedResponse: null,
            );
          });
        } else {
          // Last question or single question round
          state = currentState.copyWith(submittedResponse: submitted);
        }
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
