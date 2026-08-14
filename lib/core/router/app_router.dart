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
import '../../presentation/widgets/pages/dashboard_page.dart';
import '../../presentation/widgets/pages/forgot_password_page.dart';
import '../../presentation/widgets/pages/password_recovery_page.dart';
import '../../presentation/widgets/pages/interview_session_page.dart';
import '../../presentation/widgets/pages/interviews_page.dart';
import '../../presentation/widgets/pages/login_page.dart';
import '../../presentation/widgets/pages/onboarding_page.dart';
import '../../presentation/widgets/pages/profile_page.dart';
import '../../presentation/widgets/pages/roadmap_page.dart';
import '../../presentation/widgets/pages/sign_up_page.dart';
import '../../presentation/widgets/pages/lab_page.dart';

/// A shell destination: what the nav shows, where it points and what it paints.
///
/// Label/icon, route and page used to live in two parallel `const` lists
/// indexed against each other. Removing an entry from one and not the other
/// desynchronised the whole nav silently —every destination past the gap
/// pointed at its neighbour's route—. Keeping the three together makes that
/// class of bug unrepresentable.
class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.route,
    required this.page,
    this.inBottomNav = true,
  });

  final String label;
  final IconData icon;
  final String route;
  final Widget page;

  /// Whether it takes one of the bottom nav slots.
  final bool inBottomNav;

  AppDestination get destination =>
      AppDestination(label: label, icon: icon, inBottomNav: inBottomNav);
}

/// The shell's navigation, in display order. Profile does not take a bottom nav
/// slot: on ≤768 it is reached through the AppBar icon (§9 of the handoff).
///
/// "My path" goes first because it is the destination the user lands on when
/// finishing the onboarding: it is what closes AC 1.3.
const _shell = <_ShellDestination>[
  _ShellDestination(
    label: 'My path',
    icon: Icons.route_outlined,
    route: '/path',
    page: RoadmapPage(),
  ),
  _ShellDestination(
    label: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
    route: '/dashboard',
    page: DashboardPage(),
  ),
  _ShellDestination(
    label: 'Interviews',
    icon: Icons.record_voice_over_outlined,
    route: '/interviews',
    page: InterviewsPage(),
  ),
  _ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    route: '/profile',
    page: ProfilePage(),
    inBottomNav: false,
  ),
];

/// Built once, not per read: AppShell compares destinations by identity to work
/// out which one is selected, so handing it fresh instances would break the
/// nav highlight.
final _destinations = [
  for (final d in _shell) d.destination,
];

final _routes = [
  for (final d in _shell) d.route,
];

/// Routes reachable without a session.
const _publicRoutes = <String>{
  '/login',
  '/sign-up',
  _confirmedRoute,
  _forgotPasswordRoute,
  _recoveryRoute,
};

/// Where the confirmation email lands (issue #34).
///
/// It is public and, unlike the rest, the guard never redirects away from it
/// even with a session: whoever clicked the link has to see that it worked.
/// The page itself carries the way forward.
const _confirmedRoute = '/auth/confirmed';

/// Requesting the recovery email (issue #57). Public: whoever forgot their
/// password has no session by definition.
const _forgotPasswordRoute = '/forgot-password';

/// Where the recovery email lands (issue #57).
///
/// Like [_confirmedRoute], the guard never redirects away from it: the link
/// opens a session while the page is loading, and bouncing to `/path` at that
/// moment would leave the user signed in with the password they forgot.
const _recoveryRoute = '/auth/recovery';

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
        path: _forgotPasswordRoute,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: _recoveryRoute,
        builder: (_, __) => const PasswordRecoveryPage(),
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
          for (final destination in _shell)
            GoRoute(
              path: destination.route,
              builder: (_, __) => ColoredBox(
                color: AppColors.background,
                child: destination.page,
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

    // The confirmation and recovery landings report an outcome; bouncing away
    // from them would leave the user without knowing whether the link worked —
    // and the recovery link opens a session mid-load, which would otherwise
    // yank the user to the path still carrying the password they forgot.
    if (destination == _confirmedRoute || destination == _recoveryRoute) {
      return null;
    }

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
