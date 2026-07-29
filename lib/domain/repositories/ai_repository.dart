// Domain layer: Repository contract for AI features.
//
// Defines the interface that the data layer must implement to call Kimi3.
// The domain layer declares WHAT is needed; the data layer decides HOW
// (Supabase Edge Functions in production, a stub in tests).
//
// All methods return the rich domain entity directly: the data layer is
// responsible for mapping the raw JSON from the Edge Function to these types.

import '../entities/onboarding_answer.dart';
import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/track_recommendation.dart';

abstract interface class AiRepository {
  /// Sends the user's onboarding answers to Kimi3 and returns a full
  /// track recommendation with natural-language reasoning.
  ///
  /// Throws a [AiFailure] if the Edge Function is unreachable or the model
  /// returns an unusable response.
  ///
  /// The implementation may read a cached result from `ai_profile_insights`
  /// before calling the Edge Function, to avoid redundant LLM calls.
  Future<TrackRecommendation> analyzeProfile({
    required List<OnboardingAnswer> answers,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  });

  /// Generates a personalized daily brief for the dashboard.
  ///
  /// The result is cached for 24 hours in `ai_profile_insights` to avoid
  /// calling the LLM on every dashboard navigation.
  Future<String> generateDailyBrief({
    required String userId,
    required String trackSlug,
    required String? experienceLevelSlug,
    required String? learningGoalSlug,
    required int completedTopics,
    required int totalTopics,
  });

  /// Generates a Socratic hint for a lab challenge without revealing the answer.
  ///
  /// [attemptCount] controls the verbosity of the hint: after 3 failed
  /// attempts the hint becomes more explicit, but still never gives the answer.
  Future<String> generateLabHint({
    required String challengeQuestion,
    required String challengeType,
    required int attemptCount,
    required String? userContext,
  });

  /// Generates a short motivational coaching message for the roadmap header,
  /// personalized to the user's current progress and goal.
  Future<String> generateRoadmapCoachMessage({
    required String trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required String? nextTopicTitle,
  });
}
