// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// A finished interview-practice session, as saved to history. Unlike the
// rest of the interview state, this is persisted: it is what the history
// list and its detail view are built from.

import 'interview_answer_feedback.dart';
import 'interview_question.dart';
import 'roadmap_track.dart';

class InterviewSessionRecord {
  const InterviewSessionRecord({
    required this.id,
    required this.track,
    required this.averageScore,
    required this.createdAt,
    required this.questions,
    required this.answers,
    required this.feedback,
    this.desiredRole,
    this.overallSummary,
  });

  final String id;
  final RoadmapTrack track;

  /// The role typed on the intro screen before this session, if any.
  final String? desiredRole;

  /// Average of every question's score, rounded — the number the history
  /// list and its aggregate stat are built from.
  final int averageScore;

  final String? overallSummary;
  final DateTime createdAt;

  final List<InterviewQuestion> questions;

  /// Answer text keyed by [InterviewQuestion.id].
  final Map<String, String> answers;

  final List<InterviewAnswerFeedback> feedback;
}
