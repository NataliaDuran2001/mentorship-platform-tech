import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/lab_challenge.dart';

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
