// Tests of the guided quiz branch (issue #12).
//
// AC3 is the one that matters most: the decision rule has to come out of
// RecommendTrackUseCase and not from an `if` in the UI. It is verified by
// recording what the use case receives and checking that its output is what
// gets displayed, even when that output contradicts the apparent majority.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/track_recommendation.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/recommend_track_usecase.dart';
import 'package:aspire_app/domain/usecases/submit_onboarding_usecase.dart';
import 'package:aspire_app/domain/repositories/ai_repository.dart';
import 'package:aspire_app/domain/failures/ai_failure.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/onboarding_actions.dart';
import 'package:aspire_app/presentation/state/onboarding_state.dart';
import 'package:aspire_app/presentation/utils/onboarding_labels.dart';
import 'package:aspire_app/presentation/utils/onboarding_quiz.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';

/// Records every saved answer, to verify the persistence of AC5.
class SpyOnboardingRepository implements OnboardingRepository {
  final List<OnboardingAnswer> saved = [];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {
    saved.add(answer);
  }

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async => saved;

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
      track: track,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );
  }
}

/// AiRepository stub for the quiz test: always throws so the fake use case
/// double is the only result path.
class _OfflineAiRepository implements AiRepository {
  const _OfflineAiRepository();

  @override
  Future<TrackRecommendation> analyzeProfile({
    required List<OnboardingAnswer> answers,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async =>
      throw const AiFailure(AiFailureKind.network);

  @override
  Future<String> generateDailyBrief({
    required String userId,
    required String trackSlug,
    required String? experienceLevelSlug,
    required String? learningGoalSlug,
    required int completedTopics,
    required int totalTopics,
  }) async =>
      throw const AiFailure(AiFailureKind.network);

  @override
  Future<String> generateLabHint({
    required String challengeQuestion,
    required String challengeType,
    required int attemptCount,
    required String? userContext,
  }) async =>
      throw const AiFailure(AiFailureKind.network);

  @override
  Future<String> generateRoadmapCoachMessage({
    required String trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required String? nextTopicTitle,
  }) async =>
      throw const AiFailure(AiFailureKind.network);
}

/// Fake use case: it returns whatever it is told and notes what it received.
///
/// It serves to prove that the UI does **not** decide: if the widget had its
/// own rule, the result would not match what this double returns.
class FakeRecommendTrackUseCase extends RecommendTrackUseCase {
  FakeRecommendTrackUseCase(this.result)
      : super(const _OfflineAiRepository());

  TrackRecommendation result;
  List<OnboardingAnswer>? received;

  @override
  Future<TrackRecommendation> call(
    List<OnboardingAnswer> answers, {
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    received = answers;
    return result;
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

/// Answers the 3 questions always voting for the same track.
///
/// It looks the option up by its affinity and not by a fixed text: only the
/// first question uses the track names as labels.
Future<void> _answerAll(WidgetTester tester, RoadmapTrack track) async {
  for (final question in quizQuestions) {
    final option = question.options.firstWhere((o) => o.affinity == track);
    await tester.tap(find.text(option.label));
    await _settle(tester);
  }
}

void main() {
  late SpyOnboardingRepository repo;
  late FakeRecommendTrackUseCase recommender;

  setUp(() {
    repo = SpyOnboardingRepository();
    recommender = FakeRecommendTrackUseCase(
      const TrackRecommendation(
        track: RoadmapTrack.backend,
        scores: {
          RoadmapTrack.frontend: 0,
          RoadmapTrack.backend: 3,
          RoadmapTrack.infrastructure: 0,
        },
        wasTie: false,
      ),
    );

    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));
    overrideDependency<RecommendTrackUseCase>(recommender);

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;

    // Enter the guided branch: it is what "I'm not sure yet" does on step 2.
    usesGuidedQuiz.value = true;
    currentStepIndex.value = 2;
  });

  tearDown(cancelOnboardingTimers);

  testWidgets('it is reachable from step 2 and the counter says "of 5"',
      (tester) async {
    resetOnboarding();
    currentStepIndex.value = 1;
    await _mount(tester);

    await tester.tap(find.text(notSureOption.label));
    await _settle(tester);

    expect(currentStep.value, OnboardingStepId.quiz);
    expect(find.text('STEP 3 OF 5'), findsOneWidget);
    expect(
      find.text('What kind of problems do you enjoy solving the most?'),
      findsOneWidget,
    );
  });

  testWidgets(
      'the quiz recommends among the 3 technical tracks only; UI/UX and PM '
      'are reached by direct selection, not by quiz votes', (tester) async {
    await _mount(tester);

    expect(find.text('Front-end'), findsOneWidget);
    expect(find.text('Back-end'), findsOneWidget);
    expect(find.text('Infrastructure & DevOps'), findsOneWidget);
    expect(find.text('Mobile'), findsNothing);
    expect(find.text('UI/UX Design'), findsNothing);
    expect(find.text('Project Management'), findsNothing);
  });

  testWidgets('it walks through the questions and shows the number of each one',
      (tester) async {
    await _mount(tester);

    expect(find.textContaining('Question 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Front-end'));
    await _settle(tester);

    expect(find.textContaining('Question 2 of 3'), findsOneWidget);
    // It is still step 3 of 5: the quiz is one step, not three.
    expect(find.text('STEP 3 OF 5'), findsOneWidget);
  });

  testWidgets('the recommendation comes from the use case, not from the widget',
      (tester) async {
    await _mount(tester);

    // It votes 3 times for Front-end, but the use case returns Back-end.
    await _answerAll(tester, RoadmapTrack.frontend);

    expect(quizShowingResult.value, isTrue);
    // What is shown is what the use case said, not the apparent majority.
    expect(find.text('We found your path'), findsOneWidget);
    expect(find.text('Back-end'), findsWidgets);

    // And it received the 3 answers with their quiz_N keys.
    expect(recommender.received, hasLength(3));
    expect(
      recommender.received!.map((a) => a.stepKey),
      containsAll(<String>['quiz_1', 'quiz_2', 'quiz_3']),
    );
    expect(
      recommender.received!.every((a) => a.value == 'frontend'),
      isTrue,
    );
  });

  testWidgets('every answer is persisted with its quiz_N key', (tester) async {
    await _mount(tester);
    await _answerAll(tester, RoadmapTrack.infrastructure);

    final keys = repo.saved.map((a) => a.stepKey).toList();
    expect(keys, ['quiz_1', 'quiz_2', 'quiz_3']);
    expect(
      repo.saved.every((a) => a.value == 'infrastructure'),
      isTrue,
    );
  });

  testWidgets('the result requires confirmation: the track is not assigned on '
      'its own', (tester) async {
    await _mount(tester);
    await _answerAll(tester, RoadmapTrack.frontend);

    // With the result on screen there is still no track assigned.
    expect(selectedTrack.value, isNull);

    await tester.tap(find.text('Confirm this path'));
    await tester.pumpAndSettle();

    expect(selectedTrack.value, RoadmapTrack.backend);
    // And the flow carries on to the goal step, with the counter still at 5.
    expect(currentStep.value, OnboardingStepId.goal);
    expect(totalSteps.value, 5);
    expect(find.text('What is your main goal?'), findsOneWidget);
    expect(find.text('STEP 4 OF 5'), findsOneWidget);
  });

  testWidgets('the recommendation can be corrected by hand', (tester) async {
    await _mount(tester);
    await _answerAll(tester, RoadmapTrack.frontend);

    // The recommended one is Back-end; Infrastructure is chosen instead.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Infrastructure & DevOps'));
    await tester.pumpAndSettle();

    expect(selectedTrack.value, RoadmapTrack.infrastructure);
    expect(currentStep.value, OnboardingStepId.goal);
    // The correction is persisted too, with the key of the track step.
    expect(
      repo.saved.last.stepKey,
      'track',
    );
    expect(repo.saved.last.value, 'infrastructure');
  });

  testWidgets('a tie is reported instead of being presented as conclusive',
      (tester) async {
    recommender.result = const TrackRecommendation(
      track: RoadmapTrack.frontend,
      scores: {
        RoadmapTrack.frontend: 1,
        RoadmapTrack.backend: 1,
        RoadmapTrack.infrastructure: 1,
      },
      wasTie: true,
    );

    await _mount(tester);
    await _answerAll(tester, RoadmapTrack.frontend);

    expect(
      find.textContaining('It was close with another path'),
      findsOneWidget,
    );
  });

  testWidgets('the quiz can be taken again', (tester) async {
    await _mount(tester);
    await _answerAll(tester, RoadmapTrack.frontend);

    await tester.tap(find.text('Take the quiz again'));
    await tester.pumpAndSettle();

    expect(quizShowingResult.value, isFalse);
    expect(quizAnswers.value, isEmpty);
    expect(find.textContaining('Question 1 of 3'), findsOneWidget);
  });

  testWidgets('"Back" goes question by question and then leaves the quiz',
      (tester) async {
    await _mount(tester);

    await tester.tap(find.text('Front-end'));
    await _settle(tester);
    expect(find.textContaining('Question 2 of 3'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Question 1 of 3'), findsOneWidget);

    // From the first one, "Back" leaves the guided branch.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(currentStep.value, OnboardingStepId.track);
    expect(usesGuidedQuiz.value, isFalse);
    expect(totalSteps.value, 4);
  });

  testWidgets('"Continue" is disabled until the question is answered',
      (tester) async {
    await _mount(tester);

    final button = find.widgetWithText(ElevatedButton, 'Continue');
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    await tester.tap(find.text('Back-end'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    await _settle(tester);
  });

  testWidgets('"Skip" does not exist in the quiz', (tester) async {
    await _mount(tester);
    expect(find.text('Skip'), findsNothing);
  });
}
