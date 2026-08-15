import '../../core/di/injection.dart';
import '../../domain/entities/lab_challenge.dart';
import '../../domain/repositories/lab_repository.dart';
import '../../domain/usecases/complete_topic_usecase.dart';
import '../utils/auth_error_messages.dart';
import 'content_translation_actions.dart';
import 'content_translation_state.dart';
import 'lab_state.dart';
import 'roadmap_actions.dart';
import 'ai_actions.dart';

Future<void> loadLabs(String topicId) async {
  labTopicId.value = topicId;
  labLoading.value = true;
  labError.value = null;
  labSaveError.value = null;
  labChallenges.value = const [];
  labCurrentIndex.value = 0;
  labSelectedAnswers.value = {};
  labIsCurrentValid.value = null;
  labCheckedIndices.value = <int>{};
  labFirstTryCorrectIndices.value = <int>{};
  labTheoryTranslations.value = const {};
  labExerciseTranslations.value = const {};

  // Clear AI hints on starting a new lab topic
  clearLabHintsForTopic(topicId);

  try {
    final repo = getIt<LabRepository>();
    final challenges = await repo.getChallengesForTopic(topicId);
    labChallenges.value = challenges;

    final theoryIds = [
      for (final challenge in challenges)
        if (challenge is TheoryChallenge) challenge.id,
    ];
    final exerciseIds = [
      for (final challenge in challenges)
        if (challenge is! TheoryChallenge) challenge.id,
    ];
    await Future.wait([
      ensureLabTheoryTranslations(theoryIds),
      ensureLabExerciseTranslations(exerciseIds),
    ]);
  } catch (e) {
    labError.value = errorMessage(e);
  } finally {
    labLoading.value = false;
  }
}

/// Validates the current answers against the current challenge.
///
/// The first check of each challenge is also what the score is made of, so it
/// is recorded here and never revised afterwards (see [labCheckedIndices]).
void submitLabAnswer() {
  final challenge = labCurrentChallenge.value;
  if (challenge == null) return;

  // An explanation is acknowledged, not answered: it has no validation to run
  // and must not reach the score, or it would inflate every denominator.
  if (challenge is TheoryChallenge) return;

  final answers = labSelectedAnswers.value;

  if (challenge is MultipleChoiceChallenge) {
    final selected = answers['selected'];
    labIsCurrentValid.value = (selected == challenge.correctOptionId);
  } else if (challenge is FillBlankChallenge) {
    bool isValid = true;
    for (final entry in challenge.correctAnswers.entries) {
      if (answers[entry.key] != entry.value) {
        isValid = false;
        break;
      }
    }
    // Also ensure they provided all answers
    if (answers.length != challenge.correctAnswers.length) {
      isValid = false;
    }
    labIsCurrentValid.value = isValid;
  } else if (challenge is OrderLogicChallenge) {
    bool isValid = true;
    for (int i = 0; i < challenge.correctOrder.length; i++) {
      if (answers[i.toString()] != challenge.correctOrder[i]) {
        isValid = false;
        break;
      }
    }
    if (answers.length != challenge.correctOrder.length) {
      isValid = false;
    }
    labIsCurrentValid.value = isValid;
  }

  _recordFirstAttempt();
}

/// Writes down how the current challenge went, but only on its first check.
///
/// Every later check is a retry on the way to the right answer, and retrying
/// is how the lab is meant to work — it just does not count as knowing it.
void _recordFirstAttempt() {
  final index = labCurrentIndex.value;
  if (labCheckedIndices.value.contains(index)) return;

  labCheckedIndices.value = {...labCheckedIndices.value, index};
  if (labIsCurrentValid.value == true) {
    labFirstTryCorrectIndices.value = {
      ...labFirstTryCorrectIndices.value,
      index,
    };
  }
}

/// Advances to the next challenge and, if there is none left, closes the topic.
///
/// Solving the last challenge is what completes the topic: that is the only
/// event today that moves the roadmap forward (issue #47).
Future<void> nextLabChallenge() async {
  labIsCurrentValid.value = null;
  labSelectedAnswers.value = {};
  labCurrentIndex.value = labCurrentIndex.value + 1;

  final topicId = labTopicId.value;
  if (topicId != null) {
    clearLabHintsForTopic(topicId);
  }

  if (labIsCompleted.value) {
    await completeCurrentTopic();
  }
}

/// Records the open topic as completed and refreshes the path.
///
/// The reload is not optional: progress that is saved but not visible on the
/// path reads exactly like progress that was lost.
Future<void> completeCurrentTopic() async {
  final topicId = labTopicId.value;
  if (topicId == null) return;

  labSavingProgress.value = true;
  labSaveError.value = null;

  try {
    await getIt<CompleteTopicUseCase>()(topicId, score: labScore.value);
    await loadRoadmap();
  } catch (e) {
    labSaveError.value = errorMessage(e);
  } finally {
    labSavingProgress.value = false;
  }
}

void setLabAnswer(String key, String value) {
  final current = Map<String, String>.from(labSelectedAnswers.value);
  current[key] = value;
  labSelectedAnswers.value = current;
  // Clear validation state when user changes answer
  labIsCurrentValid.value = null;
}
