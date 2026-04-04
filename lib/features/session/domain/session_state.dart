import 'models/session.dart';
import 'models/question.dart';
import 'models/student_response.dart';

/// Sealed session state class — represents all possible states a session can be in
sealed class SessionState {
  const SessionState();
}

/// Initial state — no session joined
class SessionInitial extends SessionState {
  const SessionInitial();
}

/// Loading state — joining or fetching session
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Error state
class SessionError extends SessionState {
  final String message;
  const SessionError(this.message);
}

/// Joined but waiting for session to start (in lobby)
class SessionLobby extends SessionState {
  final Session session;
  const SessionLobby(this.session);
}

/// Session is active, question is being shown
class SessionQuestion extends SessionState {
  final Session session;
  final Question question;
  final int roundNumber;
  final StudentResponse? submittedResponse;
  final Duration timeRemaining;

  const SessionQuestion({
    required this.session,
    required this.question,
    required this.roundNumber,
    this.submittedResponse,
    required this.timeRemaining,
  });

  SessionQuestion copyWith({
    StudentResponse? submittedResponse,
    Duration? timeRemaining,
  }) {
    return SessionQuestion(
      session: session,
      question: question,
      roundNumber: roundNumber,
      submittedResponse: submittedResponse ?? this.submittedResponse,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }
}

/// Session is between questions — waiting for next
class SessionWaiting extends SessionState {
  final Session session;
  final int lastRoundNumber;
  final StudentResponse? lastResponse;

  const SessionWaiting({
    required this.session,
    required this.lastRoundNumber,
    this.lastResponse,
  });
}

/// Session has ended — show results
class SessionEnded extends SessionState {
  final Session session;
  const SessionEnded(this.session);
}

// ─── Streaming States (Remote Only) ──────────────────────────────

/// Remote student is in session but stream hasn't started yet
class SessionStreamPending extends SessionState {
  final Session session;
  const SessionStreamPending(this.session);
}

/// Remote student and stream is live
class SessionStreaming extends SessionState {
  final Session session;
  final Question? currentQuestion;
  final int? roundNumber;
  final StudentResponse? submittedResponse;
  final bool isScreenShareActive;
  final StreamLayout layout;

  const SessionStreaming({
    required this.session,
    this.currentQuestion,
    this.roundNumber,
    this.submittedResponse,
    this.isScreenShareActive = false,
    this.layout = StreamLayout.fullScreen,
  });

  SessionStreaming copyWith({
    Question? currentQuestion,
    int? roundNumber,
    StudentResponse? submittedResponse,
    bool? isScreenShareActive,
    StreamLayout? layout,
  }) {
    return SessionStreaming(
      session: session,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      roundNumber: roundNumber ?? this.roundNumber,
      submittedResponse: submittedResponse ?? this.submittedResponse,
      isScreenShareActive: isScreenShareActive ?? this.isScreenShareActive,
      layout: layout ?? this.layout,
    );
  }
}

enum StreamLayout { pipCamera, fullScreen, sideBySide }
