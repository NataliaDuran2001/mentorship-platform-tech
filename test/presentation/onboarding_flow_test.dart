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
  Future<void> saveAnswer(OnboardingAnswer answer) async {}

  @override
  Future<UserProfile> updateLanguage({required AppLanguage language}) async {
    return UserProfile(id: 'u1', email: 'ana@example.com', language: language);
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

void main() {
  late SpyOnboardingRepository repo;

  setUp(() {
    repo = SpyOnboardingRepository();
    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;
  });

  tearDown(cancelOnboardingTimers);

  group('Journey and counter', () {
    testWidgets('it starts on step 1 of 4', (tester) async {
      await _mount(tester);

      expect(find.text('STEP 1 OF 4'), findsOneWidget);
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

      // Before the timer it is still on step 1, with the option marked: that
      // is the visual feedback the pause exists to show.
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);

      await _waitForAutoAdvance(tester);

      expect(find.text('STEP 2 OF 4'), findsOneWidget);
      expect(find.text('What do you want to focus on?'), findsOneWidget);
    });

    testWidgets('the progress bar reflects the real total of steps',
        (tester) async {
      await _mount(tester);
      await tester.pumpAndSettle();

      // Step 1 of 4 → 25%, same as the prototype.
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.25, 0.001),
      );

      // On entering the guided branch the total becomes 5 and the same
      // position is worth a different fraction.
      usesGuidedQuiz.value = true;
      currentStepIndex.value = 0;
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 5'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.2, 0.001),
      );
    });
  });

  group('Step 2: specialty', () {
    testWidgets("it offers the 3 decided tracks plus the I am not sure yet option",
        (tester) async {
      currentStepIndex.value = 1;
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
      currentStepIndex.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsNothing);

      // Step 3: skippable again.
      currentStepIndex.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('What is your main goal?'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('"Continue" is disabled until a track is chosen',
        (tester) async {
      currentStepIndex.value = 1;
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
      currentStepIndex.value = 1;
      await _mount(tester);

      await tester.tap(find.text(notSureOption.label));
      await _waitForAutoAdvance(tester);

      expect(usesGuidedQuiz.value, isTrue);
      expect(selectedTrack.value, isNull);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.quiz);
      expect(find.text('STEP 3 OF 5'), findsOneWidget);
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
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
    });

    testWidgets('going back from the guided quiz reopens the track step',
        (tester) async {
      currentStepIndex.value = 1;
      await _mount(tester);

      await tester.tap(find.text(notSureOption.label));
      await _waitForAutoAdvance(tester);
      expect(currentStep.value, OnboardingStepId.quiz);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // The branch is turned off and the total goes back to 4: the user is
      // reconsidering her specialty.
      expect(usesGuidedQuiz.value, isFalse);
      expect(totalSteps.value, 4);
      expect(currentStep.value, OnboardingStepId.track);
    });

    testWidgets('on the first step "Back" is not offered', (tester) async {
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
      expect(find.text('STEP 4 OF 4'), findsOneWidget);
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
      currentStepIndex.value = 3;

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
      currentStepIndex.value = 3;
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
