// Data layer: Model that parses interview-session history from/to the
// database and maps to the InterviewSessionRecord entity of the Domain
// layer.
//
// The keys are the column names of `public.interview_sessions`, exactly as
// the migration created them. `questions`/`answers`/`feedback` travel as
// jsonb and are decoded into the same shapes InterviewRepositoryImpl already
// parses out of the analyze-interview-session Edge Function response.

import '../../domain/entities/interview_answer_feedback.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/interview_session_record.dart';
import '../../domain/entities/roadmap_track.dart';

class InterviewSessionModel {
  const InterviewSessionModel({
    required this.id,
    required this.trackId,
    required this.averageScore,
    required this.questions,
    required this.answers,
    required this.feedback,
    required this.createdAt,
    this.desiredRole,
    this.overallSummary,
  });

  /// Columns requested in a `select`. Explicit and not `*` for the same
  /// reason as UserModel.columns: adding a column later must not silently
  /// change what travels to the client.
  static const String columns = 'id, track_id, desired_role, average_score, '
      'overall_summary, questions, answers, feedback, created_at';

  final String id;
  final String trackId;
  final String? desiredRole;
  final int averageScore;
  final String? overallSummary;
  final List<dynamic> questions;
  final Map<String, dynamic> answers;
  final List<dynamic> feedback;
  final DateTime createdAt;

  factory InterviewSessionModel.fromJson(Map<String, dynamic> json) {
    return InterviewSessionModel(
      id: json['id'] as String,
      trackId: json['track_id'] as String,
      desiredRole: json['desired_role'] as String?,
      averageScore: (json['average_score'] as num).toInt(),
      overallSummary: json['overall_summary'] as String?,
      questions: json['questions'] as List<dynamic>,
      answers: (json['answers'] as Map).cast<String, dynamic>(),
      feedback: json['feedback'] as List<dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  InterviewSessionRecord toEntity() {
    return InterviewSessionRecord(
      id: id,
      // Falls back to the first track rather than throwing: a history row
      // must always be viewable, even if a track was ever renamed/removed.
      track: RoadmapTrack.fromSlug(trackId) ?? RoadmapTrack.values.first,
      desiredRole: desiredRole,
      averageScore: averageScore,
      overallSummary: overallSummary,
      createdAt: createdAt,
      questions: [
        for (final q in questions)
          InterviewQuestion(
            id: (q as Map)['id'] as String,
            prompt: q['prompt'] as String,
            category: q['category'] as String,
          ),
      ],
      answers: answers.map((key, value) => MapEntry(key, value as String)),
      feedback: [
        for (final f in feedback)
          InterviewAnswerFeedback(
            questionId: (f as Map)['questionId'] as String,
            summary: f['summary'] as String,
            strengths: (f['strengths'] as List).cast<String>(),
            improvements: (f['improvements'] as List).cast<String>(),
            score: (f['score'] as num).toInt(),
          ),
      ],
    );
  }
}
