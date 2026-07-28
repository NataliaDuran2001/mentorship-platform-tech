import '../../core/di/injection.dart';
import '../../domain/entities/lab_challenge.dart';
import '../../domain/repositories/lab_repository.dart';
import 'lab_state.dart';

Future<void> loadLabs(String topicId) async {
  labLoading.value = true;
  labError.value = null;
  labChallenges.value = const [];
  labCurrentIndex.value = 0;
  labSelectedAnswers.value = {};
  labIsCurrentValid.value = null;

  try {
    final repo = getIt<LabRepository>();
    final challenges = await repo.getChallengesForTopic(topicId);
    labChallenges.value = challenges;
  } catch (e) {
    labError.value = 'No se pudieron cargar los laboratorios: $e';
  } finally {
    labLoading.value = false;
  }
}

/// Validates the current answers against the current challenge.
void submitLabAnswer() {
  final challenge = labCurrentChallenge.value;
  if (challenge == null) return;

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
}

void nextLabChallenge() {
  labIsCurrentValid.value = null;
  labSelectedAnswers.value = {};
  labCurrentIndex.value = labCurrentIndex.value + 1;
}

void setLabAnswer(String key, String value) {
  final current = Map<String, String>.from(labSelectedAnswers.value);
  current[key] = value;
  labSelectedAnswers.value = current;
  // Clear validation state when user changes answer
  labIsCurrentValid.value = null;
}
