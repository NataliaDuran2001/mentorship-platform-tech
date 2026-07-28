import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/lab_challenge.dart';

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
