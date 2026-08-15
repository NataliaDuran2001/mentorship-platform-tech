// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// One question's worth of feedback within an InterviewSessionFeedback:
// Kimi3's read on one typed answer to one interview-practice question,
// graded alongside the rest of the session in a single call.

class InterviewAnswerFeedback {
  const InterviewAnswerFeedback({
    required this.questionId,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.score,
  });

  /// Matches InterviewQuestion.id: how the UI maps this feedback back to the
  /// question it belongs to instead of relying on list order.
  final String questionId;

  /// Short, encouraging read on the answer as a whole. Ties the score to
  /// something concrete from the answer, so it never feels arbitrary.
  final String summary;

  /// What the answer already does well.
  final List<String> strengths;

  /// Concrete, actionable ways to improve the answer.
  final List<String> improvements;

  /// 0-100. Tracks progress over time; not shown as a pass/fail gate, since
  /// practice has no wrong answers, just room to grow.
  final int score;
}
