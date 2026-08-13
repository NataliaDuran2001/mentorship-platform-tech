// Domain layer: Repository contract for the interview-practice simulator.
//
// Defines the interface the data layer must implement to call Kimi3 for
// question generation and answer feedback. Mirrors AiRepository's shape but
// lives separately: this is its own bounded feature area, not a variation on
// the daily-brief/coach/hint features.
//
// Unlike AiRepository, neither method has a deterministic fallback: there is
// no rule-based way to generate an interview question or grade an answer
// without the model, so failures propagate as AiFailure for the UI to show
// directly (no graceful degradation here).

import '../entities/experience_level.dart';
import '../entities/interview_answer_feedback.dart';
import '../entities/interview_question.dart';
import '../entities/learning_goal.dart';
import '../entities/roadmap_track.dart';

abstract interface class InterviewRepository {
  /// Generates a fresh, personalized set of interview-practice questions for
  /// [track] (and, when available, [experienceLevel]/[learningGoal]).
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
  });

  /// Sends one typed answer to Kimi3 and returns constructive feedback.
  ///
  /// Throws an AiFailure on the same conditions as [generateQuestions].
  Future<InterviewAnswerFeedback> analyzeAnswer({
    required InterviewQuestion question,
    required String answerText,
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
  });
}
