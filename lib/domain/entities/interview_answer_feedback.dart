// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// Output of InterviewRepository.analyzeAnswer: Kimi3's read on one typed
// answer to one interview-practice question.

class InterviewAnswerFeedback {
  const InterviewAnswerFeedback({
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.score,
  });

  /// Short, encouraging read on the answer as a whole.
  final String summary;

  /// What the answer already does well.
  final List<String> strengths;

  /// Concrete, actionable ways to improve the answer.
  final List<String> improvements;

  /// 0-100. Tracks progress over time; not shown as a pass/fail gate, since
  /// practice has no wrong answers, just room to grow.
  final int score;
}
