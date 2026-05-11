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
import '../features/home/presentation/screens/dashboard_screen.dart';
import '../features/chatbot/presentation/screens/ai_chatbot_screen.dart';
import '../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/session/presentation/screens/quiz_screen.dart';
import '../features/session/domain/models/remedial_assignment.dart';
import '../features/home/presentation/screens/notes_screen.dart';
import 'presentation/screens/main_layout.dart';
import 'providers/preferences_provider.dart';
import 'demo_gallery.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'theme.dart';
import '../features/parent/presentation/screens/parent_dashboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorJoinKey = GlobalKey<NavigatorState>(debugLabel: 'join');
final _shellNavigatorChatbotKey = GlobalKey<NavigatorState>(debugLabel: 'chatbot');
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
      final authState = ref.read(authStateProvider);
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Redirection logic:
      // 1. If user has NO active auth session, force onboarding (login screen)
      if (authState.value == null && !isOnboarding) {
        return '/onboarding';
      }

      // 2. If user IS logged in
      if (authState.value != null) {
        final role = authState.value?.role;
        final isParent = role == 'parent';

        // Restrict parents strictly to the parent dashboard
        if (isParent) {
          if (state.matchedLocation != '/parent_dashboard') {
            return '/parent_dashboard';
          }
          return null;
        }

        // Restrict students from accessing parent dashboard
        if (!isParent && state.matchedLocation == '/parent_dashboard') {
          return '/';
        }

        // If user is logged in (and not a parent), don't allow them to stay on onboarding
        if (isOnboarding) {
          return '/';
        }
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

      // Parent Dashboard
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/parent_dashboard',
        builder: (context, state) => const ParentDashboardScreen(),
      ),

      // Join — name + mode selection
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quiz',
        builder: (context, state) {
          final assignment = state.extra as RemedialAssignment;
          return QuizScreen(assignment: assignment);
        },
      ),

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

      // Join screen (manual code entry)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/join',
        builder: (context, state) => const HomeScreen(),
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

          // Branch 1: Notes
          StatefulShellBranch(
            navigatorKey: _shellNavigatorJoinKey,
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),

          // Branch 2: AI Chatbot
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChatbotKey,
            routes: [
              GoRoute(
                path: '/ask-ai',
                builder: (context, state) => const AiChatbotScreen(),
              ),
            ],
          ),

          // Branch 3: Leaderboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLeaderboardKey,
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),

          // Branch 4: Profile
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
    final tr = ref.watch(trProvider);
    final sessionState = ref.watch(sessionStateProvider);

    return switch (sessionState) {
      SessionInitial() => Scaffold(
          backgroundColor: AppTheme.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  tr.get('ending_class'),
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ),
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
                  child: Text(tr.get('return_to_dashboard')),
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
