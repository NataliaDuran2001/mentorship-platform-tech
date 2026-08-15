// Domain layer: Pure business entities for AI-generated Spanish translations
// of topics and theory challenges. English stays the seeded source of truth
// (see `topics`/`lab_challenges`); these are the overlay shown when the
// learner's Settings language is not English.

import 'lab_challenge.dart';

/// Translated `title`/`description` of a `TopicNode`.
class TopicTranslation {
  const TopicTranslation({required this.title, this.description});

  final String title;
  final String? description;
}

/// Translated `question`/`blocks`/`keyTakeaway` of a `TheoryChallenge`.
///
/// Code blocks inside [blocks] are never translated: the Edge Function is
/// instructed to copy them verbatim.
class TheoryTranslation {
  const TheoryTranslation({required this.question, required this.blocks, this.keyTakeaway});

  final String question;
  final List<TheoryBlock> blocks;
  final String? keyTakeaway;
}

/// Translated `question`/`description` of an exercise
/// (`MultipleChoiceChallenge`, `FillBlankChallenge`, `OrderLogicChallenge`).
///
/// [items] carries the translated option/block text keyed by the same
/// stable id the challenge already uses — the id itself is never part of
/// the translation, so it can never change which one is graded correct.
/// `null` for `FillBlankChallenge`, whose `codeSnippet`/`correctAnswers`/
/// `availableOptions` are literal code and are never translated.
class ExerciseTranslation {
  const ExerciseTranslation({required this.question, this.description, this.items});

  final String question;
  final String? description;
  final Map<String, String>? items;
}
