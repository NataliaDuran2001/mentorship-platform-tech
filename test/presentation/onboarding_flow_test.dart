// Tests of the direct onboarding flow (issue #11).
//
// What is tested is the behavior of the journey, which is where the risk is:
// which steps there are, which one can be skipped, what it keeps when going
// back, what the counter shows and what gets persisted at the end.
//
// The onboarding state and the auth state are global to the process, so every
// test resets them in setUp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/app_language.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/submit_onboarding_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/onboarding_actions.dart';
import 'package:aspire_app/presentation/state/onboarding_state.dart';
import 'package:aspire_app/presentation/utils/onboarding_labels.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';

/// Records what was saved, so we can assert on the four columns.
class SpyOnboardingRepository implements OnboardingRepository {
  RoadmapTrack? savedTrack;
  ExperienceLevel? savedLevel;
  LearningGoal? savedGoal;
  int calls = 0;
  AuthFailure? failure;

  /// Language written to the profile, and the failure to simulate on that
  /// write.
  AppLanguage? savedLanguage;
  AuthFailure? languageFailure;

  /// Every answer that went through `saveAnswer`, in order.
  final List<OnboardingAnswer> answers = <OnboardingAnswer>[];

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    calls++;
    if (failure != null) throw failure!;

    savedTrack = track;
    savedLevel = experienceLevel;
    savedGoal = learningGoal;

    return UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      experienceLevel: experienceLevel,
      track: track,
      learningGoal: learningGoal,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );
  }

  @override
  Future<UserProfile?> loadProfile() async => null;

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      const <OnboardingAnswer>[];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async => answers.add(answer);

  @override
  Future<UserProfile> updateLanguage({required AppLanguage language}) async {
    if (languageFailure != null) throw languageFailure!;
    savedLanguage = language;
    return UserProfile(id: 'u1', email: 'ana@example.com', language: language);
  }

  @override
  Future<UserProfile> updateLearningGoal({required LearningGoal goal}) async {
    return UserProfile(id: 'u1', email: 'ana@example.com', learningGoal: goal);
  }
}

/// Mounts the page on its own, with the default theme and a wide window.
Future<void> _mount(WidgetTester tester, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
}

/// Waits for the 400 ms auto-advance.
Future<void> _waitForAutoAdvance(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 600));

/// Leaves the language step behind, answered in English.
///
/// Every test in this file is about the steps that come after it, and they
/// assert on English text — which is what the language step is there to
/// decide. The step has its own group at the end of the file.
void _languageAlreadyChosen() {
  selectedLanguage.value = AppLanguage.en;
  storedStepKeys.value = <String>{
    ...storedStepKeys.value,
    OnboardingKeys.language,
  };
  currentStepIndex.value = activeSteps.value.indexOf(OnboardingStepId.level);
}

void main() {
  late SpyOnboardingRepository repo;

  setUp(() {
    repo = SpyOnboardingRepository();
    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;
    _languageAlreadyChosen();
  });

  tearDown(cancelOnboardingTimers);

  group('Journey and counter', () {
    testWidgets('after the language, the level is step 2 of 5', (tester) async {
      await _mount(tester);

      expect(find.text('STEP 2 OF 5'), findsOneWidget);
      expect(
        find.text('Hi! How would you describe yourself today?'),
        findsOneWidget,
      );
      // The 3 levels of the prototype, with their exact texts.
      expect(find.text('Student / Self-taught'), findsOneWidget);
      expect(find.text('Junior Developer'), findsOneWidget);
      expect(find.text('Career Switcher'), findsOneWidget);
    });

    testWidgets('choosing an option advances on its own after 400 ms',
        (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Junior Developer'));
      await tester.pump();

      // Before the timer it has not moved, with the option marked: that is the
      // visual feedback the pause exists to show.
      expect(find.text('STEP 2 OF 5'), findsOneWidget);
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);

      await _waitForAutoAdvance(tester);

      expect(find.text('STEP 3 OF 5'), findsOneWidget);
      expect(find.text('What do you want to focus on?'), findsOneWidget);
    });

    testWidgets('the progress bar reflects the real total of steps',
        (tester) async {
      await _mount(tester);
      await tester.pumpAndSettle();

      // Step 2 of 5 → 40%.
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.4, 0.001),
      );

      // On entering the guided branch the total becomes 6 and the same
      // position is worth a different fraction.
      usesGuidedQuiz.value = true;
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 6'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(2 / 6, 0.001),
      );
    });
  });

  group('Step 2: specialty', () {
    testWidgets("it offers the 3 decided tracks plus the I am not sure yet option",
        (tester) async {
      currentStepIndex.value = 2;
      await _mount(tester);

      expect(find.text('Front-end'), findsOneWidget);
      expect(find.text('Back-end'), findsOneWidget);
      expect(find.text('Infrastructure & DevOps'), findsOneWidget);
      expect(find.text(notSureOption.label), findsOneWidget);

      // The tracks the mockup offers but the MVP does not have.
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('UI / UX Design'), findsNothing);
    });

    testWidgets('"Skip" is not available here, but it is on steps 1 and 3',
        (tester) async {
      // Step 1: skippable.
      await _mount(tester);
      expect(find.text('Skip'), findsOneWidget);

      // Step 2: forbidden. Without a track there is no roadmap (AC 1.3).
      currentStepIndex.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsNothing);

      // Step 3: skippable again.
      currentStepIndex.value = 3;
      await tester.pumpAndSettle();
      expect(find.text('What is your main goal?'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('"Continue" is disabled until a track is chosen',
        (tester) async {
      currentStepIndex.value = 2;
      await _mount(tester);

      final button = find.widgetWithText(ElevatedButton, 'Continue');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      await tester.tap(find.text('Back-end'));
      await tester.pump();

      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);

      // Let the auto-advance run: a pending timer when the test finishes makes
      // the framework fail.
      await _waitForAutoAdvance(tester);
    });

    testWidgets("The I am not sure yet option turns on the guided branch and the counter "
        'goes to 5', (tester) async {
      currentStepIndex.value = 2;
      await _mount(tester);

      await tester.tap(find.text(notSureOption.label));
      await _waitForAutoAdvance(tester);

      expect(usesGuidedQuiz.value, isTrue);
      expect(selectedTrack.value, isNull);
      expect(totalSteps.value, 6);
      expect(currentStep.value, OnboardingStepId.quiz);
      expect(find.text('STEP 4 OF 6'), findsOneWidget);
    });
  });

  group('Back', () {
    testWidgets('it preserves what was already selected', (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Junior Developer'));
      await _waitForAutoAdvance(tester);
      await tester.tap(find.text('Front-end'));
      await _waitForAutoAdvance(tester);

      expect(find.text('What is your main goal?'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // It goes back to step 2 with Front-end still chosen.
      expect(find.text('What do you want to focus on?'), findsOneWidget);
      expect(selectedTrack.value, RoadmapTrack.frontend);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // And to step 1 with the level still chosen.
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);
      expect(find.text('STEP 2 OF 5'), findsOneWidget);
    });

    testWidgets('going back from the guided quiz reopens the track step',
        (tester) async {
      currentStepIndex.value = 2;
      await _mount(tester);

      await tester.tap(find.text(notSureOption.label));
      await _waitForAutoAdvance(tester);
      expect(currentStep.value, OnboardingStepId.quiz);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // The branch is turned off and the total goes back to 4: the user is
      // reconsidering her specialty.
      expect(usesGuidedQuiz.value, isFalse);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.track);
    });

    testWidgets('on the first step "Back" is not offered', (tester) async {
      // The first step is the language one now, so this test has to stand on
      // it rather than on the level, where going back is legitimate.
      currentStepIndex.value = 0;
      await _mount(tester);

      final button = find.widgetWithText(TextButton, 'Back');
      expect(tester.widget<TextButton>(button).onPressed, isNull);
    });
  });

  group('Summary and persistence', () {
    testWidgets('completing the flow persists level, track and goal',
        (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Junior Developer'));
      await _waitForAutoAdvance(tester);
      await tester.tap(find.text('Front-end'));
      await _waitForAutoAdvance(tester);
      await tester.tap(find.text('Land my first professional job'));
      await _waitForAutoAdvance(tester);

      // Step 4: the summary, with Level and Focus like the prototype.
      expect(find.text('STEP 5 OF 5'), findsOneWidget);
      expect(find.text("You're all set!"), findsOneWidget);
      expect(find.text('Junior Developer'), findsOneWidget);
      expect(find.text('Front-end'), findsOneWidget);
      expect(find.text('Go to Dashboard'), findsOneWidget);

      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.calls, 1);
      expect(repo.savedLevel, ExperienceLevel.juniorDeveloper);
      expect(repo.savedTrack, RoadmapTrack.frontend);
      expect(repo.savedGoal, LearningGoal.firstJob);

      // It leaves the complete profile in the state: that is what makes the
      // route guard of #9 let the user through to the dashboard.
      expect(currentProfile.value?.hasCompletedOnboarding, isTrue);
    });

    testWidgets('skipping a step saves null, not a made-up value',
        (tester) async {
      await _mount(tester);

      // Skips the level.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Infrastructure & DevOps'));
      await _waitForAutoAdvance(tester);

      // Skips the goal.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text("You're all set!"), findsOneWidget);
      // What was skipped is shown, not hidden.
      expect(find.text('Not set'), findsNWidgets(2));

      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.savedTrack, RoadmapTrack.infrastructure);
      expect(repo.savedLevel, isNull);
      expect(repo.savedGoal, isNull);
    });

    testWidgets('a failure while saving is shown translated and does not '
        'navigate', (tester) async {
      repo.failure = const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'SocketException',
      );
      selectedTrack.value = RoadmapTrack.backend;
      currentStepIndex.value = 4;

      await _mount(tester);
      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.textContaining("We couldn't connect"), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(currentProfile.value, isNull);
    });

    testWidgets('without a track nothing is saved and it goes back to step 2',
        (tester) async {
      // A state the UI cannot reach, but the rule cannot depend on that.
      currentStepIndex.value = 4;
      await _mount(tester);

      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.calls, 0);
      expect(currentStep.value, OnboardingStepId.track);
      expect(
        find.textContaining('We need to know what you want to focus on'),
        findsOneWidget,
      );
    });
  });

  group('Step 1: language', () {
    /// Rewinds to the language step, undoing what setUp did for the rest of
    /// the file.
    void onTheLanguageStep() {
      resetOnboarding();
      currentStepIndex.value = 0;
    }

    testWidgets('it comes first, in both languages, with nothing chosen',
        (tester) async {
      onTheLanguageStep();
      await _mount(tester);

      expect(find.text('STEP 1 OF 5'), findsOneWidget);
      // Its own text cannot go through tr(): this is the screen that decides
      // what tr() will answer.
      expect(
        find.text('Elige tu idioma\nChoose your language'),
        findsOneWidget,
      );
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Nothing preselected: every profile is born in English, and showing
      // that default as if it were her answer would be a lie.
      expect(selectedLanguage.value, isNull);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Continue'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('it cannot be skipped', (tester) async {
      onTheLanguageStep();
      await _mount(tester);

      // Skipping would leave the rest of the onboarding in English, which is
      // the problem this step exists to solve.
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('choosing Español saves it and repaints the next step in '
        'Spanish', (tester) async {
      onTheLanguageStep();
      await _mount(tester);

      await tester.tap(find.text('Español'));
      await _waitForAutoAdvance(tester);

      // It reached the profile, which is what every tr() in the app reads.
      expect(repo.savedLanguage, AppLanguage.es);
      // And it left a row, so resuming knows the question was already asked.
      expect(
        repo.answers.map((a) => a.stepKey),
        contains(OnboardingKeys.language),
      );
      expect(repo.answers.last.value, 'es');

      // The step it advanced to is already in Spanish. This is the whole
      // point: before, the onboarding ran in English for everyone, because
      // the language could only be changed from a profile page the guard
      // makes unreachable until the onboarding is done.
      // Including the counter, which is one more thing that used to stay in
      // English for the whole flow.
      expect(find.text('PASO 2 DE 5'), findsOneWidget);
      expect(find.text('¡Hola! ¿Cómo te describirías hoy?'), findsOneWidget);
      expect(find.text('Estudiante / Autodidacta'), findsOneWidget);
    });

    testWidgets('choosing English also advances, and writes nothing new',
        (tester) async {
      onTheLanguageStep();
      await _mount(tester);

      await tester.tap(find.text('English'));
      await _waitForAutoAdvance(tester);

      // The profile was already English, so there is nothing to update — but
      // the answer is recorded all the same, which is what tells a resumed
      // onboarding not to ask again.
      expect(repo.savedLanguage, isNull);
      expect(repo.answers.last.stepKey, OnboardingKeys.language);
      expect(currentStep.value, OnboardingStepId.level);
      expect(
        find.text('Hi! How would you describe yourself today?'),
        findsOneWidget,
      );
    });

    testWidgets('if it cannot be saved it says so and does not move on',
        (tester) async {
      onTheLanguageStep();
      repo.languageFailure = const AuthFailure(AuthFailureKind.network);
      await _mount(tester);

      await tester.tap(find.text('Español'));
      await _waitForAutoAdvance(tester);

      // Every other step tolerates a failed save and carries on, because what
      // is lost there is the resuming of one answer. Here what is lost is the
      // answer itself.
      expect(currentStep.value, OnboardingStepId.language);
      expect(selectedLanguage.value, isNull);
      expect(
        find.textContaining("We couldn't connect"),
        findsOneWidget,
      );
    });

    testWidgets('after a failure, the other language can still be chosen',
        (tester) async {
      onTheLanguageStep();
      repo.languageFailure = const AuthFailure(AuthFailureKind.network);
      await _mount(tester);

      await tester.tap(find.text('Español'));
      await _waitForAutoAdvance(tester);
      expect(currentStep.value, OnboardingStepId.language);

      // English is the language the profile already carries, so this write
      // short-circuits. It must not inherit the previous attempt's error.
      await tester.tap(find.text('English'));
      await _waitForAutoAdvance(tester);

      expect(currentStep.value, OnboardingStepId.level);
    });
  });

  group('Responsive', () {
    testWidgets('on mobile the decorative column is not shown', (tester) async {
      await _mount(tester, size: const Size(420, 1600));
      await tester.pumpAndSettle();

      expect(find.text('Your future starts here'), findsNothing);
      expect(
        find.text('Hi! How would you describe yourself today?'),
        findsOneWidget,
      );
    });

    testWidgets('on desktop it is', (tester) async {
      await _mount(tester, size: const Size(1200, 2400));
      await tester.pumpAndSettle();

      expect(find.text('Your future starts here'), findsOneWidget);
    });
  });
}
