// Domain layer: Pure business entities for Learning Engine challenges.

abstract class LabChallenge {
  const LabChallenge({
    required this.id,
    required this.topicId,
    required this.question,
    this.description,
  });

  final String id;
  final String topicId;
  final String question;
  final String? description;
}

/// A multiple choice challenge with exactly one correct option.
class MultipleChoiceChallenge extends LabChallenge {
  const MultipleChoiceChallenge({
    required super.id,
    required super.topicId,
    required super.question,
    super.description,
    required this.options,
    required this.correctOptionId,
  });

  /// Map of option ID to option text.
  final Map<String, String> options;

  /// The ID of the correct option.
  final String correctOptionId;
}

/// A fill-in-the-blank challenge.
/// 
/// The [codeSnippet] contains markers like `{{0}}`, `{{1}}` where blanks should be.
/// The [correctAnswers] maps the index of the blank (e.g. '0', '1') to the expected string.
class FillBlankChallenge extends LabChallenge {
  const FillBlankChallenge({
    required super.id,
    required super.topicId,
    required super.question,
    super.description,
    required this.codeSnippet,
    required this.correctAnswers,
    this.availableOptions,
  });

  /// Code containing placeholders like `{{0}}`.
  final String codeSnippet;

  /// Map of placeholder index (as string) to correct text.
  final Map<String, String> correctAnswers;

  /// Optional list of words the user can choose from to fill the blanks,
  /// useful for preventing syntax frustration on mobile/web.
  final List<String>? availableOptions;
}

/// A challenge where the user must drag and drop items in the correct order.
class OrderLogicChallenge extends LabChallenge {
  const OrderLogicChallenge({
    required super.id,
    required super.topicId,
    required super.question,
    super.description,
    required this.blocks,
    required this.correctOrder,
  });

  /// Map of block ID to block text (e.g., line of code).
  final Map<String, String> blocks;

  /// The ordered list of block IDs that represent the correct answer.
  final List<String> correctOrder;
}
