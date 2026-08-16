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
import 'package:aspire_app/domain/entities/app_language.dart';
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
import 'package:aspire_app/domain/usecases/submit_onboarding_usecase.dart';
import 'package:aspire_app/main.dart';
import 'package:aspire_app/presentation/state/auth_actions.dart'
    show changePassword;
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/widgets/pages/auth_confirmed_page.dart';
import 'package:aspire_app/presentation/widgets/pages/forgot_password_page.dart';
import 'package:aspire_app/presentation/widgets/pages/password_recovery_page.dart';
import 'package:aspire_app/presentation/widgets/pages/dashboard_page.dart';
import 'package:aspire_app/presentation/widgets/pages/interviews_page.dart';
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

  // --- Password recovery and change (issue #57) ---

  AuthFailure? failureOnRecovery;
  AuthFailure? failureOnConfirmRecovery;
  AuthFailure? failureOnUpdatePassword;
  final List<String> recoveryEmails = <String>[];
  final List<String> confirmedTokenHashes = <String>[];
  final List<String> updatedPasswords = <String>[];

  @override
  Future<void> requestPasswordRecovery({required String email}) async {
    if (failureOnRecovery != null) throw failureOnRecovery!;
    recoveryEmails.add(email);
  }

  @override
  Future<void> confirmPasswordRecovery({required String tokenHash}) async {
    if (failureOnConfirmRecovery != null) throw failureOnConfirmRecovery!;
    confirmedTokenHashes.add(tokenHash);
    currentSession = sessionOnSignIn;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    if (failureOnUpdatePassword != null) throw failureOnUpdatePassword!;
    updatedPasswords.add(newPassword);
  }

  void close() => _changes.close();
}

/// In-memory onboarding repository.
///
/// It behaves like the real one for the end-to-end journey: it keeps the
/// profile it is given, updates it in place and records every answer, so a
/// test can walk the onboarding the way a person does instead of setting the
/// step index by hand.
class FakeOnboardingRepository implements OnboardingRepository {
  UserProfile? profile;

  final List<OnboardingAnswer> answers = <OnboardingAnswer>[];

  @override
  Future<UserProfile?> loadProfile() async => profile;

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      const <OnboardingAnswer>[];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async =>
      answers.add(answer);

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    final updated = (profile ?? _incompleteProfile).copyWith(
      track: track,
      experienceLevel: experienceLevel,
      learningGoal: learningGoal,
      onboardingCompletedAt: DateTime(2026, 8, 16),
    );
    profile = updated;
    return updated;
  }

  @override
  Future<UserProfile> updateLanguage({required AppLanguage language}) async {
    // It must keep the onboarding incomplete: the guard reads this profile on
    // every redirect, and handing back a complete one would throw the user out
    // of the flow halfway through.
    final updated = (profile ?? _incompleteProfile).copyWith(
      language: language,
    );
    profile = updated;
    return updated;
  }

  @override
  Future<UserProfile> updateLearningGoal({required LearningGoal goal}) async {
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
    overrideDependency(SubmitOnboardingUseCase(onboarding));

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
      // Signing up has to be one tap away: before there was no way to create
      // an account.
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('there is no Google button, nor the divider that introduced it',
        (tester) async {
      _widenWindow(tester);

      await tester.pumpWidget(const MyApp());

      // It used to sit here disabled, waiting for issue #15. A control that
      // cannot be pressed only makes people wonder whether the app is broken.
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('OR'), findsNothing);
    });

    testWidgets('while signing in, the form stays on screen and the wait is '
        'inside the button', (tester) async {
      _widenWindow(tester);
      authLoading.value = true;

      await tester.pumpWidget(const MyApp());

      // The whole page used to be replaced by an indicator. With `authLoading`
      // shared between login and sign up and no timeout on the request, one
      // stalled call left every way in covered by a spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);

      // And the button does not take a second tap while the first is in
      // flight.
      final button = find.widgetWithText(ElevatedButton, 'Sign in');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
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

    testWidgets('the password can be revealed and hidden again (#33)',
        (tester) async {
      _widenWindow(tester);
      await tester.pumpWidget(const MyApp());

      TextField passwordField() => tester.widget<TextField>(
            find.byWidgetPredicate(
              (w) => w is TextField && w.decoration?.hintText == 'Password',
            ),
          );

      // It starts hidden: revealing is always an explicit act.
      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(passwordField().obscureText, isFalse);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pumpAndSettle();
      expect(passwordField().obscureText, isTrue);
    });

    testWidgets('leaving the screen hides the password again (#33)',
        (tester) async {
      _widenWindow(tester);
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(loginPasswordVisible.value, isTrue);

      // Going to sign up clears the forms; a password left revealed on screen
      // would be worse than the typo the toggle avoids.
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(loginPasswordVisible.value, isFalse);
      expect(signUpPasswordVisible.value, isFalse);
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

    testWidgets('"check your email" does not outlive the sign-up that '
        'produced it', (tester) async {
      _widenWindow(tester);
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ana@example.com');
      await tester.enterText(fields.at(2), 'secret123');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Check your email'), findsOneWidget);

      // Go to the login and come back to create another account. The pending
      // email used to survive, so this screen showed the *previous* attempt's
      // confirmation instead of an empty form.
      await tester.tap(find.text('Go to sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsNothing);
      expect(find.text('Create account'), findsOneWidget);
    });
  });

  group('The onboarding, walked end to end', () {
    // This is the manual QA pass, written down: no step index is set by hand
    // and no signal is poked. It signs in, follows the guard, taps what a
    // person taps and checks what she would see — including the whole flow
    // switching to Spanish the moment she asks for it.
    testWidgets('she signs in, picks Spanish, explains herself in her own '
        'words and reaches her path', (tester) async {
      _widenWindow(tester);
      auth.sessionOnSignIn = _session;
      onboarding.profile = _incompleteProfile;

      await tester.pumpWidget(const MyApp());

      // --- Sign in ---------------------------------------------------------
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'ana@example.com');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // The guard drops her into the onboarding, on the language step, which
      // greets her in both languages because it cannot know yet which one she
      // reads.
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('STEP 1 OF 5'), findsOneWidget);
      expect(
        find.text('Elige tu idioma\nChoose your language'),
        findsOneWidget,
      );

      // --- Step 1: Spanish -------------------------------------------------
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // From here on, everything is in Spanish. This is what did not happen
      // before: the language could only be changed from a page the guard makes
      // unreachable until the onboarding is over.
      expect(onboarding.profile!.language, AppLanguage.es);
      expect(find.text('PASO 2 DE 5'), findsOneWidget);
      expect(find.text('¡Hola! ¿Cómo te describirías hoy?'), findsOneWidget);

      // --- Step 2: none of the three describes her -------------------------
      expect(find.text('Estudiante / Autodidacta'), findsOneWidget);
      expect(find.text('Otro motivo'), findsOneWidget);

      await tester.tap(find.text('Otro motivo'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // It waits for her instead of advancing on its own.
      expect(find.text('PASO 2 DE 5'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Tengo una tienda de barrio y quiero venderle por internet',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // --- Step 3: track ---------------------------------------------------
      expect(find.text('PASO 3 DE 5'), findsOneWidget);
      await tester.tap(find.text('Front-end'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // --- Step 4: goal ----------------------------------------------------
      expect(find.text('PASO 4 DE 5'), findsOneWidget);
      await tester.tap(find.text('Conseguir mi primer empleo profesional'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // --- Step 5: summary, in her own words -------------------------------
      expect(find.text('PASO 5 DE 5'), findsOneWidget);
      expect(find.text('¡Ya está todo listo!'), findsOneWidget);
      expect(
        find.text('Tengo una tienda de barrio y quiero venderle por internet'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ir al Panel'));
      await tester.pumpAndSettle();

      // The guard lets her through, and everything she said was persisted.
      expect(find.byType(OnboardingPage), findsNothing);
      expect(onboarding.profile!.track, RoadmapTrack.frontend);
      expect(onboarding.profile!.experienceLevel, ExperienceLevel.other);

      final byKey = {for (final a in onboarding.answers) a.stepKey: a.value};
      expect(byKey['language'], 'es');
      expect(byKey['experience_level'], 'other');
      expect(
        byKey['experience_other'],
        'Tengo una tienda de barrio y quiero venderle por internet',
      );
      expect(byKey['track'], 'frontend');
      expect(byKey['goal'], 'first_job');
    });
  });

  group('Email confirmation landing (#34)', () {
    testWidgets('without a session it confirms and offers to sign in',
        (tester) async {
      _widenWindow(tester);
      AppRouter.router.go('/auth/confirmed');

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // The guard does not bounce it to the login even without a session:
      // whoever clicked the link has to see that it worked.
      expect(find.byType(AuthConfirmedPage), findsOneWidget);
      expect(find.text('Email confirmed'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('with a session it offers to continue, and the guard routes',
        (tester) async {
      _widenWindow(tester);
      currentSession.value = _session;
      currentProfile.value = _completeProfile;
      AppRouter.router.go('/auth/confirmed');

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // With a session it still shows the outcome instead of jumping into the
      // app: it is the only feedback that the confirmation worked.
      expect(find.byType(AuthConfirmedPage), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // It goes to the root and the guard decides; with the onboarding done
      // that is the learning path.
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/path',
      );
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

      await tester.tap(find.text('Interviews'));
      await tester.pumpAndSettle();

      expect(find.byType(InterviewsPage), findsOneWidget);
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.path,
        '/interviews',
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

  group('Password recovery (#57)', () {
    testWidgets(
        'from the login you reach the forgot-password page, and requesting '
        'the email neither confirms nor denies that the account exists',
        (tester) async {
      _widenWindow(tester);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot your password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ana@example.com');
      await tester.tap(find.text('Send recovery link'));
      await tester.pumpAndSettle();

      expect(auth.recoveryEmails, ['ana@example.com']);
      // Enumeration protection: the copy is conditional on purpose.
      expect(find.textContaining('If that email has an account'),
          findsOneWidget);
    });

    testWidgets('the recovery landing is never redirected away, even with a '
        'session mid-load', (tester) async {
      _widenWindow(tester);
      _withCompleteSession(); // the emailed link opens a session while loading

      AppRouter.router.go('/auth/recovery');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(PasswordRecoveryPage), findsOneWidget);
    });

    testWidgets('the token_hash of the link is exchanged for a session on '
        'arrival, before the user types anything', (tester) async {
      _widenWindow(tester);

      AppRouter.router.go('/auth/recovery?token_hash=pkce_abc123');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(auth.confirmedTokenHashes, ['pkce_abc123']);
      expect(find.text('Set a new password'), findsOneWidget);
    });

    testWidgets('an expired token_hash says so on arrival and offers a fresh '
        'link', (tester) async {
      _widenWindow(tester);
      auth.failureOnConfirmRecovery =
          const AuthFailure(AuthFailureKind.sessionExpired);

      AppRouter.router.go('/auth/recovery?token_hash=spent_token');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // No password fields were shown for a link that cannot work.
      expect(find.text('Request a new link'), findsOneWidget);
      expect(find.text('Save new password'), findsNothing);
    });

    testWidgets('mismatched passwords warn locally and never reach the '
        'backend', (tester) async {
      _widenWindow(tester);
      _withCompleteSession();

      AppRouter.router.go('/auth/recovery');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Secret123');
      await tester.enterText(find.byType(TextField).at(1), 'Different123');
      await tester.tap(find.text('Save new password'));
      await tester.pumpAndSettle();

      expect(auth.updatedPasswords, isEmpty);
      expect(find.textContaining("don't match"), findsOneWidget);
    });

    testWidgets('a valid new password is saved and confirmed', (tester) async {
      _widenWindow(tester);
      _withCompleteSession();

      AppRouter.router.go('/auth/recovery');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Secret123');
      await tester.enterText(find.byType(TextField).at(1), 'Secret123');
      await tester.tap(find.text('Save new password'));
      await tester.pumpAndSettle();

      expect(auth.updatedPasswords, ['Secret123']);
      expect(find.text('Password updated'), findsOneWidget);
    });

    testWidgets('an expired link offers to request a new one, decided by '
        'kind and not by message text', (tester) async {
      _widenWindow(tester);
      _withCompleteSession();
      auth.failureOnUpdatePassword =
          const AuthFailure(AuthFailureKind.sessionExpired);

      AppRouter.router.go('/auth/recovery');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Secret123');
      await tester.enterText(find.byType(TextField).at(1), 'Secret123');
      await tester.tap(find.text('Save new password'));
      await tester.pumpAndSettle();

      expect(find.text('Request a new link'), findsOneWidget);
    });
  });

  group('Change password from the profile (#57)', () {
    test('a wrong current password blames the right field and changes '
        'nothing', () async {
      _withCompleteSession();
      auth.failureOnSignIn =
          const AuthFailure(AuthFailureKind.invalidCredentials);

      await changePassword(
        currentPassword: 'wrong-one',
        newPassword: 'Secret123',
      );

      expect(auth.updatedPasswords, isEmpty);
      expect(passwordUpdateError.value, contains('current password'));
      expect(passwordUpdateDone.value, isFalse);
    });

    test('with the current password verified, the new one is saved',
        () async {
      _withCompleteSession();

      await changePassword(
        currentPassword: 'old-one',
        newPassword: 'Secret123',
      );

      expect(auth.updatedPasswords, ['Secret123']);
      expect(passwordUpdateError.value, isNull);
      expect(passwordUpdateDone.value, isTrue);
    });
  });
}
