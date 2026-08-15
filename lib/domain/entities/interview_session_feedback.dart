// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// Output of InterviewRepository.analyzeSession: Kimi3's read on every
// answer of an interview-practice session, graded together in one call so
// scores are calibrated against each other instead of scored in isolation.

import 'interview_answer_feedback.dart';

class InterviewSessionFeedback {
  const InterviewSessionFeedback({
    required this.overallSummary,
    required this.results,
  });

  /// Short, encouraging read on the session as a whole.
  final String overallSummary;

  /// One entry per answered question, in no particular order — matched back
  /// to questions via InterviewAnswerFeedback.questionId.
  final List<InterviewAnswerFeedback> results;
}
