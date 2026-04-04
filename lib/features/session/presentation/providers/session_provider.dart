import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../../domain/models/session.dart';
import '../../domain/models/student.dart';
import '../../domain/models/question.dart';
import '../../domain/models/student_response.dart';
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
      } else if (mode == StudentMode.remote && !session.isStreaming) {
        state = SessionStreamPending(session);
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
    _channel = Supabase.instance.client.channel('session:$sessionId');

    _channel!
        .onBroadcast(
          event: 'session:started',
          callback: (payload) => _handleSessionStarted(payload),
        )
        .onBroadcast(
          event: 'session:next_question',
          callback: (payload) => _handleNextQuestion(payload),
        )
        .onBroadcast(
          event: 'session:ended',
          callback: (payload) => _handleSessionEnded(payload),
        )
        .onBroadcast(
          event: 'session:result',
          callback: (payload) => _handleResult(payload),
        )
        .onBroadcast(
          event: 'stream:started',
          callback: (payload) => _handleStreamStarted(payload),
        )
        .onBroadcast(
          event: 'stream:ended',
          callback: (payload) => _handleStreamEnded(payload),
        )
        .subscribe();
  }

  void _handleSessionStarted(Map<String, dynamic> payload) {
    final currentState = state;
    if (currentState is SessionLobby) {
      state = SessionWaiting(
          session: currentState.session, lastRoundNumber: 0);
    } else if (currentState is SessionStreamPending) {
      state = SessionWaiting(
          session: currentState.session, lastRoundNumber: 0);
    }
  }

  void _handleNextQuestion(Map<String, dynamic> payload) async {
    try {
      final sessionId = _ref.read(currentSessionIdProvider);
      if (sessionId == null) return;

      final roundNumber = payload['round_number'] as int? ?? 1;
      final question = await _repo.getQuestionForRound(sessionId, roundNumber);

      if (question == null) return;

      final session = await _repo.getSession(sessionId);
      final mode = _ref.read(studentModeProvider);

      if (mode == StudentMode.remote) {
        // Remote students get streaming state with question overlay
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
    } catch (e) {
      // Silently handle — keep current state
    }
  }

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

  void _handleSessionEnded(Map<String, dynamic> payload) async {
    _timer?.cancel();
    try {
      final sessionId = _ref.read(currentSessionIdProvider);
      if (sessionId == null) return;
      final session = await _repo.getSession(sessionId);
      state = SessionEnded(session);
    } catch (_) {}
  }

  void _handleResult(Map<String, dynamic> payload) {
    // Results can be handled here if needed
  }

  void _handleStreamStarted(Map<String, dynamic> payload) {
    final currentState = state;
    final mode = _ref.read(studentModeProvider);

    if (mode == StudentMode.remote) {
      Session? session;
      if (currentState is SessionStreamPending) {
        session = currentState.session;
      } else if (currentState is SessionLobby) {
        session = currentState.session;
      }
      if (session != null) {
        state = SessionStreaming(
          session: session.copyWith(
            isStreaming: true,
            livekitRoomName: payload['livekitRoomName'] as String?,
          ),
        );
      }
    }
  }

  void _handleStreamEnded(Map<String, dynamic> payload) {
    final currentState = state;
    if (currentState is SessionStreaming) {
      // Stream ended but session may still be active
      state = SessionWaiting(
        session: currentState.session,
        lastRoundNumber: currentState.roundNumber ?? 0,
      );
    }
  }

  /// Submit a response to the current question
  Future<void> submitResponse(ResponseType response,
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
