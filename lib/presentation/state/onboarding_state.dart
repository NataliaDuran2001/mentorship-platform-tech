// Presentation layer (State): Onboarding state with signals.
//
// It only declares signals and derived values; the one that changes them is
// onboarding_actions.dart.
//
// The core idea is that the flow has **two branches** and therefore a variable
// step total: 4 if the user picks their track directly, 5 if they pick "I'm not
// sure yet" and go through the guided quiz. Instead of spreading that count
// around the UI, the list of active steps is declared and everything else is
// derived from it: the counter, the progress bar and which step to show. That
// is where the mismatch between the two prototype mockups came from.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/track_recommendation.dart';
import '../utils/onboarding_quiz.dart';

/// The possible steps. `quiz` only takes part in the guided branch.
enum OnboardingStepId { language, level, track, quiz, goal, summary }

/// The user picked "I'm not sure yet" on step 2 and goes through the guided
/// quiz.
final usesGuidedQuiz = signal<bool>(false);

/// Index within [activeSteps], starting at 0.
final currentStepIndex = signal<int>(0);

/// Language picked on step 1, or `null` while it has not been picked.
///
/// It is not derived from [appLanguage]: that one always has a value —every
/// profile is born with `language = 'en'`— so it could never tell "she chose
/// English" from "nobody has been asked yet", and the step would start with an
/// answer already filled in.
final selectedLanguage = signal<AppLanguage?>(null);

final selectedLevel = signal<ExperienceLevel?>(null);
final selectedTrack = signal<RoadmapTrack?>(null);
final selectedGoal = signal<LearningGoal?>(null);

// ---------------------------------------------------------------------------
// Guided quiz (issue #12)
//
// The quiz is **one** step of the counter, not one per question: the prototype
// shows "Step 02/05" for the whole guide. That is why its internal navigation
// lives here, apart from currentStepIndex.
// ---------------------------------------------------------------------------

/// Quiz answers: question number → track it voted for.
final quizAnswers = signal<Map<int, RoadmapTrack>>(<int, RoadmapTrack>{});

/// Question being shown, starting at 0.
final quizQuestionIndex = signal<int>(0);

/// All of them are answered already and the result is being shown.
final quizShowingResult = signal<bool>(false);

/// Output of RecommendTrackUseCase. `null` while it has not been computed.
final quizRecommendation = signal<TrackRecommendation?>(null);

/// AI-First: `true` while Kimi3 is analyzing the quiz answers.
///
/// The UI shows a loading indicator during this time so the user knows
/// the AI is working, not that the app is frozen.
final quizAnalyzing = signal<bool>(false);

/// Current question of the quiz.
final currentQuizQuestion = computed<QuizQuestion>(() {
  final index = quizQuestionIndex.value.clamp(0, quizQuestions.length - 1);
  return quizQuestions[index];
});

/// The current question is already answered.
final currentQuizAnswered = computed(
  () => quizAnswers.value.containsKey(currentQuizQuestion.value.number),
);

/// Keys of `onboarding_answers` that already have a row for this user, either
/// answered or skipped.
///
/// It exists so the resume flow can tell "I skipped it" from "I never got
/// there": a `null` selection is not enough, because skipping also leaves the
/// selection at `null`.
final storedStepKeys = signal<Set<String>>(<String>{});

/// Saving the final result.
final onboardingSaving = signal<bool>(false);

/// Error message, already translated.
final onboardingError = signal<String?>(null);

/// The steps that are actually walked through, in order.
///
/// It is the only definition of the journey: the counter, the bar and the
/// internal routing are derived from here, so they cannot disagree.
final activeSteps = computed<List<OnboardingStepId>>(() {
  return usesGuidedQuiz.value
      ? const [
          OnboardingStepId.language,
          OnboardingStepId.level,
          OnboardingStepId.track,
          OnboardingStepId.quiz,
          OnboardingStepId.goal,
          OnboardingStepId.summary,
        ]
      : const [
          OnboardingStepId.language,
          OnboardingStepId.level,
          OnboardingStepId.track,
          OnboardingStepId.goal,
          OnboardingStepId.summary,
        ];
});

/// 5 on the direct branch, 6 on the guided one. It includes the summary, just
/// like the prototype's "Step 1 of 4".
final totalSteps = computed(() => activeSteps.value.length);

/// Current step. It clamps the index in case the list got shorter when coming
/// back from the guided branch to the direct one.
final currentStep = computed<OnboardingStepId>(() {
  final steps = activeSteps.value;
  final index = currentStepIndex.value.clamp(0, steps.length - 1);
  return steps[index];
});

/// Visible step number, starting at 1.
final currentStepNumber = computed(
  () => currentStepIndex.value.clamp(0, totalSteps.value - 1) + 1,
);

/// Fraction for the progress bar, over the real total of steps.
final onboardingProgress =
    computed(() => currentStepNumber.value / totalSteps.value);

/// Going back is possible.
final canGoBack = computed(() => currentStepIndex.value > 0);

/// The current step can be skipped.
///
/// Only the level and the goal. The track is **not** skippable: without a track
/// there is no roadmap to unfold and AC 1.3 would be violated. Neither is the
/// guided quiz, because it exists precisely to get that track. Nor is the
/// language: skipping it would leave the rest of the onboarding in English,
/// which is the exact problem the step was added to solve.
final canSkipCurrentStep = computed(() {
  switch (currentStep.value) {
    case OnboardingStepId.level:
    case OnboardingStepId.goal:
      return true;
    case OnboardingStepId.language:
    case OnboardingStepId.track:
    case OnboardingStepId.quiz:
    case OnboardingStepId.summary:
      return false;
  }
});

/// The current step has an answer that allows moving forward.
///
/// On the track step it requires a real selection: that is what keeps
/// "Continue" disabled until there is a track. On the quiz it requires the
/// visible question to be answered, and on the result screen, that there is a
/// recommendation to confirm.
final canAdvance = computed(() {
  switch (currentStep.value) {
    case OnboardingStepId.level:
    case OnboardingStepId.goal:
    case OnboardingStepId.summary:
      return true;
    case OnboardingStepId.language:
      return selectedLanguage.value != null;
    case OnboardingStepId.track:
      return selectedTrack.value != null;
    case OnboardingStepId.quiz:
      return quizShowingResult.value
          ? quizRecommendation.value?.hasRecommendation ?? false
          : currentQuizAnswered.value;
  }
});

/// Leaves the flow as if it had just started. It is called when leaving the
/// onboarding.
void resetOnboarding() {
  usesGuidedQuiz.value = false;
  currentStepIndex.value = 0;
  quizAnswers.value = <int, RoadmapTrack>{};
  quizQuestionIndex.value = 0;
  quizShowingResult.value = false;
  quizRecommendation.value = null;
  quizAnalyzing.value = false;
  storedStepKeys.value = <String>{};
  selectedLanguage.value = null;
  selectedLevel.value = null;
  selectedTrack.value = null;
  selectedGoal.value = null;
  onboardingSaving.value = false;
  onboardingError.value = null;
}
