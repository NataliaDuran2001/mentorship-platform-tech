import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/lab_challenge.dart';
import '../../domain/entities/lab_score.dart';

/// The topic the open lab belongs to.
///
/// It is kept because finishing the lab has to close that topic in the
/// roadmap, and by then the route parameter is no longer at hand (issue #47).
final labTopicId = signal<String?>(null);

/// The challenges for the current topic.
final labChallenges = signal<List<LabChallenge>>(<LabChallenge>[]);

/// True when loading the challenges from the repository.
final labLoading = signal<bool>(false);

/// Error message if loading fails.
final labError = signal<String?>(null);

/// The index of the challenge the user is currently on.
final labCurrentIndex = signal<int>(0);

/// The current challenge being displayed.
final labCurrentChallenge = computed<LabChallenge?>(() {
  if (labChallenges.value.isEmpty) return null;
  if (labCurrentIndex.value >= labChallenges.value.length) return null;
  return labChallenges.value[labCurrentIndex.value];
});

/// Map holding the user's current answers.
/// - For MultipleChoice: {'selected': 'optionId'}
/// - For FillBlank: {'0': 'word1', '1': 'word2'}
/// - For OrderLogic: {'0': 'blockId', '1': 'blockId2', ...} (as an ordered map of string indices)
final labSelectedAnswers = signal<Map<String, String>>({});

/// Real-time validation result.
/// `null` means not checked yet.
/// `true` means correct.
/// `false` means incorrect.
final labIsCurrentValid = signal<bool?>(null);

/// Indices of the challenges that have already been checked at least once.
///
/// This is what makes the score a *first-try* reading: the outcome of a
/// challenge is written down the first time it is checked and never revised,
/// so the retries that follow move the lab forward without rewriting history.
final labCheckedIndices = signal<Set<int>>(<int>{});

/// Indices of the challenges answered right on the very first check.
///
/// A subset of [labCheckedIndices]: what is in one and not the other is what
/// the learner had to retry.
final labFirstTryCorrectIndices = signal<Set<int>>(<int>{});

/// How the open lab went, counted in the steps the learner walked through.
///
/// Explanations are counted apart from exercises because they are earned
/// differently —read versus answered right first time— but both are steps of
/// the lesson and both end up in the number that closes it.
final labScore = computed<LabScore>(() {
  final challenges = labChallenges.value;
  final firstTry = labFirstTryCorrectIndices.value;

  var exercisesTotal = 0;
  var exercisesCorrect = 0;
  var concepts = 0;
  for (var i = 0; i < challenges.length; i++) {
    if (challenges[i] is TheoryChallenge) {
      concepts++;
      continue;
    }
    exercisesTotal++;
    if (firstTry.contains(i)) exercisesCorrect++;
  }

  return LabScore(
    exercisesCorrect: exercisesCorrect,
    exercisesTotal: exercisesTotal,
    concepts: concepts,
  );
});

/// The questions that took more than one try, in the order they were met.
///
/// The closing screen names them: "4 of 5" says how it went, but only the
/// titles say what to go back to.
final labMissedQuestions = computed<List<String>>(() {
  final challenges = labChallenges.value;
  final checked = labCheckedIndices.value;
  final firstTry = labFirstTryCorrectIndices.value;

  return [
    for (var i = 0; i < challenges.length; i++)
      if (challenges[i] is! TheoryChallenge &&
          checked.contains(i) &&
          !firstTry.contains(i))
        challenges[i].question,
  ];
});

/// True when all challenges are completed.
final labIsCompleted = computed(() {
  if (labChallenges.value.isEmpty) return false;
  return labCurrentIndex.value >= labChallenges.value.length;
});

/// The completion of the topic is being recorded.
final labSavingProgress = signal<bool>(false);

/// The completion could not be recorded. `null` if there is nothing to report.
///
/// It is separate from [labError]: the challenges did load and the user did
/// solve them, so the lab is not broken —only their progress did not stick,
/// and that is retryable without replaying anything.
final labSaveError = signal<String?>(null);
