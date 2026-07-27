// Tests of the persistence and resuming of an unfinished onboarding (issue
// #14).
//
// The fake repository emulates the real upsert of `onboarding_answers`: key
// (user, `step_key`). That is what allows verifying that resuming does not
// pile up rows, which is AC5.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/recommend_track_usecase.dart';
import 'package:aspire_app/domain/usecases/submit_onboarding_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/onboarding_actions.dart';
import 'package:aspire_app/presentation/state/onboarding_state.dart';
import 'package:aspire_app/presentation/utils/onboarding_labels.dart';
import 'package:aspire_app/presentation/utils/onboarding_quiz.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';

/// In-memory repository with the same upsert semantics as the table.
class FakeOnboardingRepository implements OnboardingRepository {
  final Map<String, OnboardingAnswer> rows = <String, OnboardingAnswer>{};

  /// How many writes were requested, to tell "it updated" from "it piled up".
  int writes = 0;

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {
    writes++;
    // unique (user_id, step_key): the key is the step, not the row.
    rows[answer.stepKey] = answer;
  }

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      rows.values.toList(growable: false);

  @override
  Future<UserProfile?> loadProfile() async => null;

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    return UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      experienceLevel: experienceLevel,
      track: track,
      learningGoal: learningGoal,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );
  }
}

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
}

Future<void> _settle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 600));

/// Simulates closing the browser: all the in-memory state is lost, only what
/// is in the database remains.
void _simulateBrowserClose() {
  cancelOnboardingTimers();
  resetOnboarding();
}

void main() {
  late FakeOnboardingRepository repo;

  setUp(() {
    repo = FakeOnboardingRepository();
    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));
    overrideDependency<RecommendTrackUseCase>(const RecommendTrackUseCase());

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;
  });

  tearDown(cancelOnboardingTimers);

  group('Persistence on selection', () {
    testWidgets('every answer is saved before completing the flow',
        (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Junior Developer'));
      await _settle(tester);

      // It is already in the database, without having finished the onboarding.
      expect(repo.rows.keys, contains('experience_level'));
      expect(repo.rows['experience_level']!.value, 'junior_developer');

      await tester.tap(find.text('Front-end'));
      await _settle(tester);

      expect(repo.rows['track']!.value, 'frontend');

      await tester.tap(find.text('Land my first professional job'));
      await _settle(tester);

      expect(repo.rows['goal']!.value, 'first_job');
      // And the profile has not been marked as complete yet.
      expect(currentProfile.value, isNull);
    });

    testWidgets("The I am not sure yet option is saved too", (tester) async {
      currentStepIndex.value = 1;
      await _mount(tester);

      await tester.tap(find.text(notSureOption.label));
      await _settle(tester);

      // Saving "unknown" is what allows knowing, when resuming, that she asked
      // for the guide and not that she left the step unanswered.
      expect(repo.rows['track']!.value, 'unknown');
    });

    testWidgets('changing an answer updates the row, it does not pile up',
        (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Junior Developer'));
      await _settle(tester);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Career Switcher'));
      await _settle(tester);

      // Two writes, a single row, with the new value.
      expect(repo.writes, 2);
      expect(
        repo.rows.keys.where((k) => k == 'experience_level'),
        hasLength(1),
      );
      expect(repo.rows['experience_level']!.value, 'career_switcher');
    });
  });

  group('Resuming on the direct branch', () {
    testWidgets('coming back resumes on step 3, with steps 1 and 2 marked',
        (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Junior Developer'));
      await _settle(tester);
      await tester.tap(find.text('Front-end'));
      await _settle(tester);

      // She is on step 3 and abandons.
      expect(find.text('What is your main goal?'), findsOneWidget);
      _simulateBrowserClose();

      // The in-memory state is gone.
      expect(selectedLevel.value, isNull);
      expect(selectedTrack.value, isNull);

      await restoreOnboarding();
      await _mount(tester);
      await tester.pumpAndSettle();

      // It resumes on step 3.
      expect(currentStep.value, OnboardingStepId.goal);
      expect(find.text('STEP 3 OF 4'), findsOneWidget);
      // With steps 1 and 2 already marked.
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);
      expect(selectedTrack.value, RoadmapTrack.frontend);
    });

    testWidgets('going back shows the previous selections marked',
        (tester) async {
      repo.rows['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.rows['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'backend');

      await restoreOnboarding();
      await _mount(tester);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Step 2 shows Back-end as chosen.
      expect(currentStep.value, OnboardingStepId.track);
      expect(selectedTrack.value, RoadmapTrack.backend);
    });

    testWidgets('with nothing saved it starts on step 1', (tester) async {
      await restoreOnboarding();
      await _mount(tester);

      expect(currentStep.value, OnboardingStepId.level);
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
    });

    testWidgets('with everything answered it resumes on the summary',
        (tester) async {
      repo.rows['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.rows['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'backend');
      repo.rows['goal'] =
          const OnboardingAnswer(stepKey: 'goal', value: 'middle_level');

      await restoreOnboarding();
      await _mount(tester);

      expect(currentStep.value, OnboardingStepId.summary);
      expect(find.text("You're all set!"), findsOneWidget);
    });
  });

  group('Skipping leaves a trace', () {
    testWidgets('a skipped step is saved as "skipped"', (tester) async {
      await _mount(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(repo.rows['experience_level']!.value, 'skipped');
    });

    testWidgets('resuming does not go back to a step that was skipped on '
        'purpose', (tester) async {
      await _mount(tester);

      // Skips the level and picks the track.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Front-end'));
      await _settle(tester);

      _simulateBrowserClose();
      await restoreOnboarding();
      await _mount(tester);
      await tester.pumpAndSettle();

      // It picks up on the goal, not on the level she already decided to skip.
      expect(currentStep.value, OnboardingStepId.goal);
      expect(selectedLevel.value, isNull);
      expect(selectedTrack.value, RoadmapTrack.frontend);
    });
  });

  group('Resuming on the guided quiz branch', () {
    testWidgets('it resumes on the first unanswered question', (tester) async {
      repo.rows['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.rows['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'unknown');
      repo.rows['quiz_1'] =
          const OnboardingAnswer(stepKey: 'quiz_1', value: 'backend');

      await restoreOnboarding();
      await _mount(tester);

      // Guided branch recognized: 5 steps.
      expect(usesGuidedQuiz.value, isTrue);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.quiz);
      // With number 1 already answered, it picks up on number 2.
      expect(find.textContaining('Question 2 of 3'), findsOneWidget);
      expect(quizAnswers.value[1], RoadmapTrack.backend);
    });

    testWidgets('with the 3 answered and not confirmed, it goes back to the '
        'result', (tester) async {
      repo.rows['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.rows['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'unknown');
      for (final q in quizQuestions) {
        repo.rows['quiz_${q.number}'] = OnboardingAnswer(
          stepKey: 'quiz_${q.number}',
          value: 'infrastructure',
        );
      }

      await restoreOnboarding();
      await _mount(tester);

      expect(quizShowingResult.value, isTrue);
      // The recommendation is recomputed with the real use case: 3 votes for
      // infrastructure.
      expect(quizRecommendation.value?.track, RoadmapTrack.infrastructure);
      expect(find.text('We found your path'), findsOneWidget);
    });

    testWidgets('with the track already confirmed it stays on the goal and '
        'the counter keeps the 5 steps', (tester) async {
      // On confirming, step 2 was overwritten with the real track; the trace
      // of the guided branch are the quiz answers.
      repo.rows['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.rows['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'frontend');
      repo.rows['quiz_1'] =
          const OnboardingAnswer(stepKey: 'quiz_1', value: 'frontend');

      await restoreOnboarding();
      await _mount(tester);

      expect(usesGuidedQuiz.value, isTrue);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.goal);
      expect(find.text('STEP 4 OF 5'), findsOneWidget);
    });
  });

  group('No path reaches the dashboard without a track', () {
    test('a profile without a track does not count as a complete onboarding',
        () {
      const withoutTrack = UserProfile(id: 'u1', email: 'ana@example.com');

      expect(withoutTrack.hasCompletedOnboarding, isFalse);
      expect(
        withoutTrack
            .copyWith(onboardingCompletedAt: DateTime(2026, 7, 26))
            .hasCompletedOnboarding,
        isFalse,
      );
    });

    testWidgets('skipping everything skippable does not allow finishing '
        'without a track', (tester) async {
      await _mount(tester);

      // Skips the level.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // On the track step there is no "Skip" and "Continue" is disabled.
      expect(find.text('Skip'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Continue'),
            )
            .onPressed,
        isNull,
      );
      // So there is no way to reach the summary without a track.
      expect(currentStep.value, OnboardingStepId.track);
    });

    testWidgets('forcing the summary without a track saves nothing and goes '
        'back to step 2', (tester) async {
      // A state unreachable through the UI; the rule cannot depend on that.
      currentStepIndex.value = 3;
      await _mount(tester);

      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(currentProfile.value, isNull);
      expect(currentStep.value, OnboardingStepId.track);
    });
  });
}
