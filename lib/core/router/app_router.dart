// Core layer (Router): route definitions with go_router, session route guards
// and wiring of the responsive shell. Login, sign up and onboarding live
// outside the ShellRoute, with no visible nav.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../config/app_branding.dart';
import '../../presentation/utils/app_colors.dart';
import '../../presentation/state/auth_actions.dart';
import '../../presentation/state/auth_state.dart';
import '../../presentation/widgets/organisms/app_shell.dart';
import '../../presentation/widgets/pages/auth_confirmed_page.dart';
import '../../presentation/widgets/pages/chat_page.dart';
import '../../presentation/widgets/pages/dashboard_page.dart';
import '../../presentation/widgets/pages/interview_session_page.dart';
import '../../presentation/widgets/pages/interviews_page.dart';
import '../../presentation/widgets/pages/logic_page.dart';
import '../../presentation/widgets/pages/login_page.dart';
import '../../presentation/widgets/pages/onboarding_page.dart';
import '../../presentation/widgets/pages/profile_page.dart';
import '../../presentation/widgets/pages/roadmap_page.dart';
import '../../presentation/widgets/pages/sign_up_page.dart';
import '../../presentation/widgets/pages/lab_page.dart';

/// Shell destinations and their routes, in the same order. Profile does not
/// take a bottom nav slot: on ≤768 it is reached through the AppBar icon (§9
/// of the handoff).
///
/// "My path" goes first because it is the destination the user lands on when
/// finishing the onboarding: it is what closes AC 1.3.
const _destinations = <AppDestination>[
  AppDestination(label: 'My path', icon: Icons.route_outlined),
  AppDestination(label: 'Dashboard', icon: Icons.space_dashboard_outlined),
  AppDestination(label: 'Chat', icon: Icons.chat_bubble_outline),
  AppDestination(label: 'Logic', icon: Icons.psychology_outlined),
  AppDestination(label: 'Interviews', icon: Icons.record_voice_over_outlined),
  AppDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    inBottomNav: false,
  ),
];

const _routes = <String>[
  '/path',
  '/dashboard',
  '/chat',
  '/logic',
  '/interviews',
  '/profile',
];

/// Routes reachable without a session.
const _publicRoutes = <String>{'/login', '/sign-up', _confirmedRoute};

/// Where the confirmation email lands (issue #34).
///
/// It is public and, unlike the rest, the guard never redirects away from it
/// even with a session: whoever clicked the link has to see that it worked.
/// The page itself carries the way forward.
const _confirmedRoute = '/auth/confirmed';

/// The only route allowed with a session and an incomplete onboarding.
const _onboardingRoute = '/onboarding';

class AppRouter {
  AppRouter._();

  /// Re-evaluates the guards when the session or the profile changes.
  ///
  /// go_router needs a Listenable and signals are not one: this bridge turns
  /// an `effect` into notifications. It is what makes signing in, finishing
  /// the onboarding or signing out redirect without any screen calling
  /// `context.go()` by hand.
  static final _SignalsRefreshListenable _refresh =
      _SignalsRefreshListenable();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _refresh,
    redirect: _guard,
    routes: [
      // Root: alias of the learning path route, so that reloading on '/' does
      // not give a 404 and so it lands where the Module 1 content is.
      GoRoute(path: '/', redirect: (_, __) => '/path'),

      // Outside the shell: no visible nav.
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpPage()),
      GoRoute(
        path: _confirmedRoute,
        builder: (_, __) => const AuthConfirmedPage(),
      ),
      GoRoute(
        path: _onboardingRoute,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/lab/:topicId',
        builder: (context, state) {
          final topicId = state.pathParameters['topicId']!;
          return LabPage(topicId: topicId);
        },
      ),
      GoRoute(
        path: '/interviews/session',
        builder: (_, __) => const InterviewSessionPage(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          final index = _routes.indexOf(state.uri.path);
          return AppShell(
            title: AppBranding.name,
            destinations: _destinations,
            // If the route is not in the list (it should not happen inside
            // the shell), it falls back to the dashboard so as not to break
            // the nav.
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (i) => context.go(_routes[i]),
            onLogout: signOut,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/path',
            builder: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: RoadmapPage(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: ChatPage(),
            ),
          ),
          GoRoute(
            path: '/logic',
            builder: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: LogicPage(),
            ),
          ),
          GoRoute(
            path: '/interviews',
            builder: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: InterviewsPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: ProfilePage(),
            ),
          ),
        ],
      ),
    ],
  );

  /// The three cases of issue #9:
  ///
  /// 1. No session → `/login`.
  /// 2. Session with an incomplete onboarding → `/onboarding`.
  /// 3. Session with a complete onboarding → `/path`.
  ///
  /// It also holds for direct URL access: the guard runs on every navigation,
  /// including the first one, so typing `/dashboard` in the browser bar
  /// without a session ends up at the login.
  ///
  /// "Complete onboarding" is asked to `hasCompletedOnboarding`, which
  /// requires `track` on top of the timestamp. That is what guarantees that no
  /// path reaches the dashboard with a null `track_id` (policy of #14).
  static String? _guard(BuildContext context, GoRouterState state) {
    final destination = state.matchedLocation;
    final isPublic = _publicRoutes.contains(destination);

    // The confirmation landing reports an outcome; bouncing away from it
    // would leave the user without knowing whether the link worked.
    if (destination == _confirmedRoute) return null;

    if (!isAuthenticated.value) {
      return isPublic ? null : '/login';
    }

    if (!hasCompletedOnboarding.value) {
      return destination == _onboardingRoute ? null : _onboardingRoute;
    }

    // With the onboarding finished, login, sign up and onboarding no longer
    // apply. It lands on the learning path route and not on the dashboard: it
    // is AC 1.3 —"when the path is defined the topic tree is displayed"—.
    if (isPublic || destination == _onboardingRoute) return '/path';
    return null;
  }
}

/// Bridge between the authentication signals and go_router's
/// `refreshListenable`.
class _SignalsRefreshListenable extends ChangeNotifier {
  _SignalsRefreshListenable() {
    _cancel = effect(() {
      // Reading them inside the effect is what subscribes to them.
      currentSession.value;
      currentProfile.value;
      notifyListeners();
    });
  }

  late final void Function() _cancel;

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}
