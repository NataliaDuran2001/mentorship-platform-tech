// Widget tests of the app: authentication screens, route guards and the
// navigation shell (issues #1, #5, #9).
//
// The auth_state signals are global to the process and AppRouter's GoRouter is
// a single instance, so every test resets both in setUp so as not to inherit
// the previous one's state.
//
// Authentication is exercised against doubles of the repositories registered
// in getIt: neither Supabase nor the network is touched. That is what allows
// testing login, sign up, sign out and the three guards in the normal suite,
// which runs in seconds.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/core/router/app_router.dart';
import 'package:aspire_app/domain/entities/auth_session.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/auth_repository.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/sign_in_usecase.dart';
import 'package:aspire_app/domain/usecases/sign_out_usecase.dart';
import 'package:aspire_app/domain/usecases/sign_up_usecase.dart';
import 'package:aspire_app/main.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/widgets/pages/chat_page.dart';
import 'package:aspire_app/presentation/widgets/pages/dashboard_page.dart';
import 'package:aspire_app/presentation/widgets/pages/login_page.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';
import 'package:aspire_app/presentation/widgets/pages/roadmap_page.dart';
import 'package:aspire_app/presentation/widgets/pages/sign_up_page.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// In-memory authentication repository.
///
/// It returns whatever it is configured with and records what it was asked
/// for. It throws `AuthFailure` just like the real one, because part of what
/// is being tested is that the UI translates those failures into messages for
/// the user.
class FakeAuthRepository implements AuthRepository {
  AuthSession? sessionOnSignIn;
  AuthFailure? failureOnSignIn;
  AuthFailure? failureOnSignUp;
  bool signUpRequiresConfirmation = true;

  int resends = 0;
  int signOuts = 0;
  String? lastResendEmail;

  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? currentSession;

  @override
  Stream<AuthSession?> get sessionChanges => _changes.stream;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (failureOnSignIn != null) throw failureOnSignIn!;
    currentSession = sessionOnSignIn;
    return AuthResult(session: sessionOnSignIn);
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (failureOnSignUp != null) throw failureOnSignUp!;
    return AuthResult(
      requiresEmailConfirmation: signUpRequiresConfirmation,
      session: signUpRequiresConfirmation ? null : sessionOnSignIn,
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    throw UnimplementedError('issue #15');
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    currentSession = null;
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    resends++;
    lastResendEmail = email;
  }

  void close() => _changes.close();
}

/// In-memory onboarding repository. It only returns the configured profile.
class FakeOnboardingRepository implements OnboardingRepository {
  UserProfile? profile;

  @override
  Future<UserProfile?> loadProfile() async => profile;

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      const <OnboardingAnswer>[];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {}

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    throw UnimplementedError();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _session = AuthSession(userId: 'u1', email: 'ana@example.com');

/// Profile just created by the trigger: nothing from the onboarding yet.
const _incompleteProfile = UserProfile(id: 'u1', email: 'ana@example.com');

/// Profile with the onboarding finished. It needs a track and a timestamp.
final _completeProfile = UserProfile(
  id: 'u1',
  email: 'ana@example.com',
  experienceLevel: ExperienceLevel.juniorDeveloper,
  track: RoadmapTrack.frontend,
  learningGoal: LearningGoal.firstJob,
  onboardingCompletedAt: DateTime(2026, 7, 26),
);

/// Sets the logical size of the test window (devicePixelRatio 1).
void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Widens the window: the whole form does not fit in the default 800x600 and
/// the overflow would pollute the assertions.
void _widenWindow(WidgetTester tester) =>
    _setWindow(tester, const Size(1200, 2000));

/// Leaves the app with a session and the onboarding finished.
void _withCompleteSession() {
  currentSession.value = _session;
  currentProfile.value = _completeProfile;
}

void main() {
  late FakeAuthRepository auth;
  late FakeOnboardingRepository onboarding;

  setUp(() {
    auth = FakeAuthRepository();
    onboarding = FakeOnboardingRepository();

    overrideDependency<AuthRepository>(auth);
    overrideDependency<OnboardingRepository>(onboarding);
    overrideDependency(SignInUseCase(auth));
    overrideDependency(SignUpUseCase(auth));
    overrideDependency(SignOutUseCase(auth));

    currentSession.value = null;
    currentProfile.value = null;
    authLoading.value = false;
    pendingConfirmationEmail.value = null;
    clearAuthForms();
    AppRouter.router.go('/login');
  });

  tearDown(() => auth.close());

  group('LoginPage', () {
    testWidgets('mounts and renders its texts in English', (tester) async {
      _widenWindow(tester);

      await tester.pumpWidget(const MyApp());

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      // Signing up has to be one tap away: before there was no way to create
      // an account.
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('the Google button is visible but disabled (#15)',
        (tester) async {
      _widenWindow(tester);

      await tester.pumpWidget(const MyApp());

      final button =
          find.widgetWithText(OutlinedButton, 'Continue with Google');
      expect(button, findsOneWidget);
      // Visible but unwired: not even to a stub that fails.
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    });

    testWidgets('with authLoading on, the indicator is shown', (tester) async {
      _widenWindow(tester);
      authLoading.value = true;

      await tester.pumpWidget(const MyApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Continue with Google'),
        findsNothing,
      );
    });

    testWidgets('without filling in the fields it warns and does not call the '
        'backend', (tester) async {
      _widenWindow(tester);
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Fill in your email and your password.'),
        findsOneWidget,
      );
      expect(currentSession.value, isNull);
    });
  });

  group('Login against the repository', () {
    testWidgets('correct credentials open a session and the guard moves to '
        'the onboarding', (tester) async {
      _widenWindow(tester);
      auth.sessionOnSignIn = _session;
      onboarding.profile = _incompleteProfile;

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(currentSession.value, isNotNull);
      expect(isAuthenticated.value, isTrue);
      // Profile without onboarding: the guard sends to the onboarding, not to
      // the dashboard.
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/onboarding',
      );
    });

    testWidgets('an unconfirmed account fails with a message and offers to '
        'resend', (tester) async {
      _widenWindow(tester);
      auth.failureOnSignIn =
          const AuthFailure(AuthFailureKind.emailNotConfirmed);

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Your account isn't confirmed yet"),
        findsOneWidget,
      );
      // No session, and no raw backend text in sight.
      expect(currentSession.value, isNull);
      expect(find.textContaining('Email not confirmed'), findsNothing);

      // The resend is offered only in this case.
      final resend = find.text('Resend confirmation email');
      expect(resend, findsOneWidget);

      await tester.tap(resend);
      await tester.pumpAndSettle();

      expect(auth.resends, 1);
      expect(auth.lastResendEmail, 'ana@example.com');
    });

    testWidgets('invalid credentials do not offer to resend the email',
        (tester) async {
      _widenWindow(tester);
      auth.failureOnSignIn =
          const AuthFailure(AuthFailureKind.invalidCredentials);

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text("That email or password isn't right."),
        findsOneWidget,
      );
      expect(find.text('Resend confirmation email'), findsNothing);
    });

    testWidgets('a network error is shown translated', (tester) async {
      _widenWindow(tester);
      auth.failureOnSignIn = const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'SocketException: Failed host lookup',
      );

      await tester.pumpWidget(const MyApp());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining("We couldn't connect"), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
    });
  });

  group('Sign up', () {
    testWidgets('a successful sign up shows "check your email", not a session',
        (tester) async {
      _widenWindow(tester);
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);

      // Name, email and password, in that order.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'new@example.com');
      await tester.enterText(fields.at(2), 'secret123');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      // With mailer_autoconfirm off there is no session: it has to be
      // confirmed.
      expect(currentSession.value, isNull);
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.textContaining('We sent an email to new@example.com'),
        findsOneWidget,
      );

      await tester.tap(find.text("It didn't arrive, resend the email"));
      await tester.pumpAndSettle();

      expect(auth.resends, 1);
      expect(find.text('Email resent.'), findsOneWidget);
    });

    testWidgets('an already registered email is reported', (tester) async {
      _widenWindow(tester);
      auth.failureOnSignUp =
          const AuthFailure(AuthFailureKind.emailAlreadyRegistered);

      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ana@example.com');
      await tester.enterText(fields.at(2), 'secret123');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("There's already an account with that email"),
        findsOneWidget,
      );
      expect(find.text('Check your email'), findsNothing);
    });
  });

  group('Route guards', () {
    testWidgets('without a session, direct URL access to a protected route '
        'lands on the login', (tester) async {
      _widenWindow(tester);

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/login',
      );
      // The login lives outside the shell: no bottom nav and no sidebar.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('with a session and an incomplete onboarding, any route lands '
        'on the onboarding', (tester) async {
      _widenWindow(tester);
      currentSession.value = _session;
      currentProfile.value = _incompleteProfile;

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      // The onboarding also lives outside the shell.
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets('with the onboarding complete, login and onboarding redirect '
        'to the learning path route', (tester) async {
      _widenWindow(tester);
      _withCompleteSession();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // It lands on /path and not on the dashboard: it is AC 1.3, "once the
      // path is defined the topic tree is displayed".
      expect(find.byType(RoadmapPage), findsOneWidget);

      AppRouter.router.go('/onboarding');
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/path',
      );
    });

    testWidgets('a profile with a timestamp but no track does not count as '
        'complete', (tester) async {
      _widenWindow(tester);
      currentSession.value = _session;
      // It is the state that the policy of #14 forbids letting through to the
      // dashboard.
      currentProfile.value = _incompleteProfile.copyWith(
        onboardingCompletedAt: DateTime(2026, 7, 26),
      );

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });

  group('Sign out', () {
    testWidgets('signing out from the shell goes back to the login and clears '
        'the state', (tester) async {
      _widenWindow(tester); // desktop: the sidebar has the action
      _withCompleteSession();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapPage), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(auth.signOuts, 1);
      expect(currentSession.value, isNull);
      expect(currentProfile.value, isNull);
      expect(isAuthenticated.value, isFalse);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('Navigation shell', () {
    testWidgets('you navigate between the destinations and the URL reflects it',
        (tester) async {
      _widenWindow(tester); // 1200 logical: desktop mode with sidebar
      _withCompleteSession();

      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/chat',
      );
    });

    testWidgets('it changes shape at the 480 and 768 breakpoints',
        (tester) async {
      _withCompleteSession();

      // Mobile (≤480): bottom nav, no drawer and no sidebar.
      _setWindow(tester, const Size(440, 900));
      AppRouter.router.go('/dashboard');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);

      // Middle range (481–768): bottom nav + drawer (hamburger).
      tester.view.physicalSize = const Size(600, 900);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Desktop (>768): fixed sidebar, no bottom nav and no hamburger.
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(find.text('Dashboard'), findsWidgets); // sidebar + placeholder
    });
  });
}
