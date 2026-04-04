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
import '../features/home/presentation/screens/dashboard_screen.dart';
import '../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import 'presentation/screens/main_layout.dart';
import 'providers/preferences_provider.dart';
import 'demo_gallery.dart';

import 'providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorJoinKey = GlobalKey<NavigatorState>(debugLabel: 'join');
final _shellNavigatorLeaderboardKey = GlobalKey<NavigatorState>(debugLabel: 'leaderboard');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class RouterNotifier extends ChangeNotifier {
  final Ref ref;
  RouterNotifier(this.ref) {
    ref.listen(studentNameProvider, (_, __) => notifyListeners());
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      final studentName = ref.read(studentNameProvider);
      final authState = ref.read(authStateProvider);
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Redirection logic:
      // 1. If user has NO active auth session, force onboarding (login screen)
      if (authState.value == null && !isOnboarding) {
        return '/onboarding';
      }

      // 2. If user IS logged in, don't allow them to stay on onboarding
      if (authState.value != null && isOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      // Onboarding — initial name setup
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Demo gallery — preview all screens
      GoRoute(
        path: '/demo',
        builder: (context, state) => const DemoGallery(),
      ),

      // Join — name + mode selection
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/join/:code',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return JoinScreen(sessionCode: code);
        },
      ),

      // Active Session — Full screen overlay
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/session',
        builder: (context, state) => const _SessionRouter(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Join Code Entry
          StatefulShellBranch(
            navigatorKey: _shellNavigatorJoinKey,
            routes: [
              GoRoute(
                path: '/join-tab',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 2: Leaderboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLeaderboardKey,
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
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
      SessionInitial() => const Center(child: Text('No active class.\nJoin one from the Join tab!', textAlign: TextAlign.center)),
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
                  child: const Text('Return to Dashboard'),
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
