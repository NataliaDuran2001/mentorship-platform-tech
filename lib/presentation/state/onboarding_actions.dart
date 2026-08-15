// Presentation layer (State): Onboarding actions.
//
// Together with auth_actions.dart, it is the only place in `presentation` that
// touches getIt. The step organisms do not know how to move forward or save:
// they report what was chosen and these functions decide.
//
// The 400 ms auto-advance uses `Timer` and not `Future.delayed` on purpose: it
// makes clear that it is an interface pause —so the selection feedback can be
// seen before changing step— and not a simulated network request, which is what
// AC2 of issue #9 forbids reintroducing.

import 'dart:async';

import '../../core/di/injection.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/onboarding_answer.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/recommend_track_usecase.dart';
import '../../domain/usecases/submit_onboarding_usecase.dart';
import '../utils/auth_error_messages.dart';
import '../utils/constants.dart';
import '../utils/onboarding_quiz.dart';
import 'auth_state.dart';
import 'language_state.dart';
import 'onboarding_state.dart';
// quizAnalyzing is declared in onboarding_state.dart and imported above.

Timer? _autoAdvance;

/// Picks the experience level and moves forward.
///
/// The answer is persisted **when it is chosen**, not at the end of the flow:
/// that is what makes the onboarding resumable (issue #14).
void selectLevel(ExperienceLevel level) {
  selectedLevel.value = level;
  _persistAnswer(OnboardingKeys.experienceLevel, level.slug);
  _advanceWithFeedback();
}

/// Picks the track and moves forward.
///
/// `null` stands for "I'm not sure yet": it turns on the guided quiz branch,
/// which changes the step total from 4 to 5.
void selectTrack(RoadmapTrack? track) {
  selectedTrack.value = track;
  usesGuidedQuiz.value = track == null;
  // "I'm not sure yet" is saved too: when resuming we need to know the user
  // asked for the guide, not that they left the step unanswered.
  _persistAnswer(
    OnboardingKeys.track,
    track?.slug ?? OnboardingKeys.unknownTrackValue,
  );
  _advanceWithFeedback();
}

/// Picks the goal and moves forward.
void selectGoal(LearningGoal goal) {
  selectedGoal.value = goal;
  _persistAnswer(OnboardingKeys.goal, goal.slug);
  _advanceWithFeedback();
}

/// Moves to the next step without waiting.
void goToNextStep() {
  _autoAdvance?.cancel();
  if (currentStepIndex.value < totalSteps.value - 1) {
    currentStepIndex.value = currentStepIndex.value + 1;
  }
}

/// Goes back to the previous step keeping what was already chosen.
///
/// It erases no selection: that is what makes going back show the marked
/// option. If coming back from the guided quiz, the branch is turned off,
/// because the user is reconsidering the track step.
void goToPreviousStep() {
  _autoAdvance?.cancel();
  if (currentStepIndex.value == 0) return;

  final previous = activeSteps.value[currentStepIndex.value - 1];
  if (currentStep.value == OnboardingStepId.quiz ||
      previous == OnboardingStepId.quiz) {
    // We are going back to the track step: the decision is reopened.
    usesGuidedQuiz.value = false;
    selectedTrack.value = null;
    currentStepIndex.value =
        activeSteps.value.indexOf(OnboardingStepId.track);
    return;
  }

  currentStepIndex.value = currentStepIndex.value - 1;
}

/// Skips the current step without answering it.
///
/// It is only reached from the skippable steps: the onboarding footer does not
/// show "Skip" on the others. The check is here anyway, because a rule that
/// depends on the UI not offering the button is not a rule.
void skipCurrentStep() {
  if (!canSkipCurrentStep.value) return;

  // Skipping leaves a trace. Without it, resuming would send the user back to a
  // step they already decided to skip, because a `null` selection looks the
  // same as a step they never reached.
  final key = _stepKey(currentStep.value);
  if (key != null) {
    _persistAnswer(key, OnboardingKeys.skippedValue);
  }

  goToNextStep();
}

/// `onboarding_answers` key of the step, or `null` if the step saves nothing.
String? _stepKey(OnboardingStepId step) {
  switch (step) {
    case OnboardingStepId.level:
      return OnboardingKeys.experienceLevel;
    case OnboardingStepId.track:
      return OnboardingKeys.track;
    case OnboardingStepId.goal:
      return OnboardingKeys.goal;
    case OnboardingStepId.quiz:
    case OnboardingStepId.summary:
      return null;
  }
}

/// Saves the onboarding result and returns `true` if it went well.
///
/// Without a track nothing is saved: the use case requires it by types and the
/// database requires it by constraint, so getting here without a track is a
/// bug, not a state to tolerate in silence.
Future<bool> submitOnboarding() async {
  final level = selectedLevel.value;
  final track = selectedTrack.value;
  final goal = selectedGoal.value;

  if (track == null) {
    onboardingError.value =
        'We need to know what you want to focus on to build your path.';
    currentStepIndex.value = activeSteps.value.indexOf(OnboardingStepId.track);
    return false;
  }

  onboardingSaving.value = true;
  onboardingError.value = null;

  try {
    // Level and goal go exactly as they ended up: if they were skipped, they
    // travel as `null` and are saved as `null`. Putting a default value would
    // be inventing the user's data, and both columns are nullable precisely
    // for this.
    final profile = await getIt<SubmitOnboardingUseCase>()(
      track: track,
      experienceLevel: level,
      learningGoal: goal,
    );

    // It leaves a fresh profile in the state so the route guards let the user
    // into the dashboard without having to read it from the database again.
    currentProfile.value = profile;
    return true;
  } catch (e) {
    onboardingError.value = errorMessage(e);
    return false;
  } finally {
    onboardingSaving.value = false;
  }
}

// ---------------------------------------------------------------------------
// Resuming (issue #14)
// ---------------------------------------------------------------------------

/// Reads the saved partial state and leaves the flow ready to continue.
///
/// It is called when reading the profile of a user with the onboarding
/// unfinished, that is, before the screen is mounted. Resuming means rebuilding
/// two things: the previous selections —so they show up marked— and the first
/// unanswered step, which is where we have to land.
Future<void> restoreOnboarding() async {
  final List<OnboardingAnswer> answers;
  try {
    answers = await getIt<OnboardingRepository>().loadAnswers();
  } catch (_) {
    // If the partial state cannot be read we start from scratch, which is the
    // behavior from before #14: a worse experience, not an error.
    return;
  }
  if (answers.isEmpty) return;

  final byKey = <String, String>{
    for (final a in answers) a.stepKey: a.value,
  };
  storedStepKeys.value = byKey.keys.toSet();

  selectedLevel.value =
      ExperienceLevel.fromSlug(byKey[OnboardingKeys.experienceLevel]);
  selectedGoal.value = LearningGoal.fromSlug(byKey[OnboardingKeys.goal]);
  selectedTrack.value = RoadmapTrack.fromSlug(byKey[OnboardingKeys.track]);

  final fromQuiz = _quizAnswersFrom(answers);
  quizAnswers.value = fromQuiz;

  // The guided branch is recognized by either of two traces: step 2 saved as
  // "unknown", or quiz answers already given. The second one matters because
  // when the recommendation is confirmed step 2 is overwritten with the real
  // track, and without that trace the counter would go back to saying "of 4".
  usesGuidedQuiz.value =
      byKey[OnboardingKeys.track] == OnboardingKeys.unknownTrackValue ||
          fromQuiz.isNotEmpty;

  _placeInQuiz(fromQuiz);
  currentStepIndex.value = _firstUnansweredStep();
}

Map<int, RoadmapTrack> _quizAnswersFrom(
  List<OnboardingAnswer> answers,
) {
  final result = <int, RoadmapTrack>{};
  for (final a in answers) {
    if (!a.stepKey.startsWith(OnboardingKeys.quizPrefix)) continue;
    final number =
        int.tryParse(a.stepKey.substring(OnboardingKeys.quizPrefix.length));
    final track = RoadmapTrack.fromSlug(a.value);
    if (number != null && track != null) result[number] = track;
  }
  return result;
}

/// Leaves the quiz on the first unanswered question, or on the result if they
/// are all done.
void _placeInQuiz(Map<int, RoadmapTrack> answered) {
  if (!usesGuidedQuiz.value) return;

  final index = quizQuestions.indexWhere(
    (q) => !answered.containsKey(q.number),
  );

  if (index >= 0) {
    quizQuestionIndex.value = index;
    quizShowingResult.value = false;
    return;
  }

  // All answered. If the track still needs confirming, the result is shown
  // again, recomputed by the use case.
  quizQuestionIndex.value = quizQuestions.length - 1;
  if (selectedTrack.value == null) {
    _computeRecommendation();
  }
}

/// Index of the first step of the journey that has no answer.
///
/// If they are all answered, it lands on the summary.
int _firstUnansweredStep() {
  final steps = activeSteps.value;

  for (var i = 0; i < steps.length; i++) {
    switch (steps[i]) {
      case OnboardingStepId.level:
        // It asks for the saved row and not for the selection: skipping leaves
        // the selection at `null` just like never having got there.
        if (!storedStepKeys.value.contains(OnboardingKeys.experienceLevel)) {
          return i;
        }
      case OnboardingStepId.track:
        // With the guided branch on, step 2 is already answered: the answer was
        // "I'm not sure".
        if (selectedTrack.value == null && !usesGuidedQuiz.value) return i;
      case OnboardingStepId.quiz:
        if (selectedTrack.value == null) return i;
      case OnboardingStepId.goal:
        if (!storedStepKeys.value.contains(OnboardingKeys.goal)) return i;
      case OnboardingStepId.summary:
        return i;
    }
  }
  return steps.length - 1;
}

// ---------------------------------------------------------------------------
// Guided quiz (issue #12)
// ---------------------------------------------------------------------------

/// Answers the visible question of the quiz and moves forward.
///
/// The answer is persisted the moment it is chosen, not at the end: that is
/// what feeds the resuming of #14 and what AC5 of this issue requires.
Future<void> answerQuizQuestion(RoadmapTrack affinity) async {
  final question = currentQuizQuestion.value;

  // A new map and not an in-place mutation: a signal compares by identity and
  // would not notify if the same map is modified.
  quizAnswers.value = <int, RoadmapTrack>{
    ...quizAnswers.value,
    question.number: affinity,
  };

  await _persistAnswer(
    OnboardingKeys.quizQuestion(question.number),
    affinity.slug,
  );

  _advanceInQuizWithFeedback();
}

/// Goes back to the previous question of the quiz, or to the track step if it
/// is already on the first one.
void goToPreviousQuizQuestion() {
  cancelOnboardingTimers();

  if (quizShowingResult.value) {
    quizShowingResult.value = false;
    return;
  }
  if (quizQuestionIndex.value > 0) {
    quizQuestionIndex.value = quizQuestionIndex.value - 1;
    return;
  }
  // On the first question, "Back" leaves the quiz.
  goToPreviousStep();
}

/// Moves to the next question or computes the recommendation if it was the
/// last one.
Future<void> advanceQuiz() async {
  cancelOnboardingTimers();

  if (quizQuestionIndex.value < quizQuestions.length - 1) {
    quizQuestionIndex.value = quizQuestionIndex.value + 1;
    return;
  }
  await _computeRecommendation();
}

/// Accepts the recommended track and carries on to the goal step.
///
/// `usesGuidedQuiz` is left at `true` on purpose: the journey still had 5 steps
/// and the counter has to keep saying so.
Future<void> confirmRecommendedTrack() async {
  final track = quizRecommendation.value?.track;
  if (track == null) return;
  await _assignQuizTrack(track);
}

/// Overrides the recommendation by hand and carries on to the goal step.
Future<void> overrideRecommendedTrack(RoadmapTrack track) =>
    _assignQuizTrack(track);

/// Goes back to the questions to answer them again.
void redoQuiz() {
  cancelOnboardingTimers();
  quizAnswers.value = <int, RoadmapTrack>{};
  quizQuestionIndex.value = 0;
  quizShowingResult.value = false;
  quizRecommendation.value = null;
}

Future<void> _assignQuizTrack(RoadmapTrack track) async {
  selectedTrack.value = track;
  await _persistAnswer(OnboardingKeys.track, track.slug);
  goToNextStep();
}

/// The decision rule is NOT here: it comes out of the domain use case, which is
/// what AC3 of this issue verifies. This method only translates the map of
/// answers into the format of the contract.
Future<void> _computeRecommendation() async {
  final answers = [
    for (final entry in quizAnswers.value.entries)
      OnboardingAnswer(
        stepKey: OnboardingKeys.quizQuestion(entry.key),
        value: entry.value.slug,
      ),
  ];

  // AI-First: show loading while Kimi3 analyzes the full profile.
  quizAnalyzing.value = true;
  try {
    quizRecommendation.value = await getIt<RecommendTrackUseCase>()(
      answers,
      experienceLevel: selectedLevel.value,
      learningGoal: selectedGoal.value,
      language: appLanguage.value,
    );
  } finally {
    quizAnalyzing.value = false;
  }
  quizShowingResult.value = true;
}

/// Saves a single answer, without breaking the flow if it fails.
///
/// A network failure while saving cannot stall the onboarding: the user loses
/// the resuming of that step, not the step. The final result is persisted all
/// the same in `submitOnboarding()`, which does report the error.
Future<void> _persistAnswer(String stepKey, String value) async {
  // It is marked as saved as soon as it is attempted: resuming within this
  // session should not depend on the round trip to the backend being finished.
  storedStepKeys.value = <String>{...storedStepKeys.value, stepKey};

  try {
    await getIt<OnboardingRepository>().saveAnswer(
      OnboardingAnswer(stepKey: stepKey, value: value),
    );
  } catch (_) {
    // Deliberate silence. See the comment above.
  }
}

void _advanceInQuizWithFeedback() {
  _autoAdvance?.cancel();
  _autoAdvance = Timer(AppConstants.durationMedium, advanceQuiz);
}

/// Cancels the pending timer. For the tests and when leaving the screen.
void cancelOnboardingTimers() {
  _autoAdvance?.cancel();
  _autoAdvance = null;
}

/// Moves forward after a short pause, so the selection can be seen.
void _advanceWithFeedback() {
  _autoAdvance?.cancel();
  _autoAdvance = Timer(AppConstants.durationMedium, goToNextStep);
}
