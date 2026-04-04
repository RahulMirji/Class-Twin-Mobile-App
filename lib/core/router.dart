import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/session/presentation/screens/home_screen.dart';
import '../features/session/presentation/screens/join_screen.dart';
import '../features/session/presentation/screens/lobby_screen.dart';
import '../features/session/presentation/screens/question_screen.dart';
import '../features/session/presentation/screens/waiting_screen.dart';
import '../features/session/presentation/screens/session_end_screen.dart';
import '../features/session/presentation/providers/session_provider.dart';
import '../features/session/domain/session_state.dart';
import '../features/stream/presentation/screens/stream_screen.dart';
import '../features/stream/presentation/screens/stream_ended_screen.dart';
import 'demo_gallery.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Home — session code entry
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // Demo gallery — preview all screens
      GoRoute(
        path: '/demo',
        builder: (context, state) => const DemoGallery(),
      ),

      // Join — name + mode selection
      GoRoute(
        path: '/join/:code',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return JoinScreen(sessionCode: code);
        },
      ),

      // Session routes — state-driven screen selection
      GoRoute(
        path: '/session',
        builder: (context, state) {
          return const _SessionRouter();
        },
        routes: [
          GoRoute(
            path: 'lobby',
            builder: (context, state) => const LobbyScreen(),
          ),
          GoRoute(
            path: 'question',
            builder: (context, state) => const QuestionScreen(),
          ),
          GoRoute(
            path: 'waiting',
            builder: (context, state) => const WaitingScreen(),
          ),
          GoRoute(
            path: 'stream',
            builder: (context, state) => const StreamScreen(),
          ),
          GoRoute(
            path: 'stream-ended',
            builder: (context, state) => const StreamEndedScreen(),
          ),
          GoRoute(
            path: 'ended',
            builder: (context, state) => const SessionEndScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Session router — determines which screen to show based on session state
class _SessionRouter extends ConsumerWidget {
  const _SessionRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);

    return switch (sessionState) {
      SessionInitial() => const HomeScreen(),
      SessionLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      SessionError(message: final msg) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(msg, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      SessionLobby() => const LobbyScreen(),
      SessionStreamPending() => const LobbyScreen(),
      SessionQuestion() => const QuestionScreen(),
      SessionWaiting() => const WaitingScreen(),
      SessionEnded() => const SessionEndScreen(),
      SessionStreaming() => const StreamScreen(),
    };
  }
}
