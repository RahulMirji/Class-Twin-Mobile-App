import '../features/session/domain/models/session.dart';
import '../features/session/domain/models/student.dart';
import '../features/session/domain/models/question.dart';
import '../features/session/domain/models/student_response.dart';
import '../features/session/domain/session_state.dart';

/// Demo mock data — used when previewing screens without a backend
class DemoData {
  DemoData._();

  static final session = Session(
    id: 'demo-session-001',
    joinCode: 'DEMO01',
    topic: 'Introduction to Neural Networks',
    totalRounds: 5,
    currentRound: 2,
    status: SessionStatus.active,
    createdBy: 'Prof. Sharma',
    isStreaming: true,
    chatEnabled: true,
    handRaiseEnabled: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    updatedAt: DateTime.now(),
  );

  static final student = Student(
    id: 'demo-student-001',
    sessionId: 'demo-session-001',
    studentName: 'Arun',
    mode: StudentMode.remote,
    joinedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );

  static final question = Question(
    id: 'demo-question-001',
    sessionId: 'demo-session-001',
    roundNumber: 2,
    questionText: 'Do you understand back-propagation?',
    options: ['Got it perfectly', 'I am somewhat lost', 'I need a recap'],
    timeLimitSeconds: 30,
    createdAt: DateTime.now(),
  );

  static final response = StudentResponse(
    id: 'demo-response-001',
    questionId: 'demo-question-001',
    studentId: 'demo-student-001',
    sessionId: 'demo-session-001',
    response: 'Got it perfectly',
    respondedAt: DateTime.now(),
  );

  // Pre-built states for demo
  static SessionLobby get lobbyState => SessionLobby(session);
  
  static SessionQuestion get questionState => SessionQuestion(
        session: session,
        question: question,
        roundNumber: 2,
        timeRemaining: const Duration(seconds: 22),
      );

  static SessionWaiting get waitingState => SessionWaiting(
        session: session,
        lastRoundNumber: 2,
        lastResponse: response,
      );

  static SessionStreaming get streamingState => SessionStreaming(
        session: session,
        currentQuestion: question,
        roundNumber: 2,
      );

  static SessionEnded get endedState => SessionEnded(session);
}
