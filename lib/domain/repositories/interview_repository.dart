// Domain layer: Repository contract for the interview-practice simulator.
//
// Defines the interface the data layer must implement to call Kimi3 for
// question generation and end-of-session answer feedback. Mirrors
// AiRepository's shape but lives separately: this is its own bounded
// feature area, not a variation on the daily-brief/coach/hint features.
//
// Unlike AiRepository, neither method has a deterministic fallback: there is
// no rule-based way to generate an interview question or grade an answer
// without the model, so failures propagate as AiFailure for the UI to show
// directly (no graceful degradation here).

import '../entities/app_language.dart';
import '../entities/experience_level.dart';
import '../entities/interview_question.dart';
import '../entities/interview_session_feedback.dart';
import '../entities/interview_session_record.dart';
import '../entities/learning_goal.dart';
import '../entities/roadmap_track.dart';

abstract interface class InterviewRepository {
  /// Generates a fresh, personalized set of interview-practice questions for
  /// [track] (and, when available, [experienceLevel]/[learningGoal]/
  /// [desiredRole]).
  ///
  /// Never cached: repeated calls are expected to return different
  /// questions — dynamic variation is a requirement of the feature, not a
  /// side effect to avoid.
  ///
  /// Throws an AiFailure if the Edge Function is unreachable or the model
  /// returns an unusable response.
  Future<List<InterviewQuestion>> generateQuestions({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
    String? desiredRole,
    required AppLanguage language,
  });

  /// Sends every answered question of the session to Kimi3 in a single call
  /// and returns feedback for all of them together, graded relative to each
  /// other so scores stay varied and justified instead of arbitrary.
  ///
  /// [answers] must have one entry per question in [questions], keyed by
  /// InterviewQuestion.id.
  ///
  /// Throws an AiFailure on the same conditions as [generateQuestions].
  Future<InterviewSessionFeedback> analyzeSession({
    required List<InterviewQuestion> questions,
    required Map<String, String> answers,
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    required AppLanguage language,
  });

  /// Persists a finished session to history. Best-effort from the caller's
  /// point of view: a failure here must never block the results screen the
  /// student already earned from showing.
  Future<void> saveSession({
    required RoadmapTrack track,
    String? desiredRole,
    required List<InterviewQuestion> questions,
    required Map<String, String> answers,
    required InterviewSessionFeedback feedback,
  });

  /// Every session the authenticated user has finished, most recent first.
  Future<List<InterviewSessionRecord>> loadSessions();
}
