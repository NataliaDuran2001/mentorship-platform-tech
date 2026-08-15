// Domain layer: Repository contract for AI features.
//
// Defines the interface that the data layer must implement to call Kimi3.
// The domain layer declares WHAT is needed; the data layer decides HOW
// (Supabase Edge Functions in production, a stub in tests).
//
// All methods return the rich domain entity directly: the data layer is
// responsible for mapping the raw JSON from the Edge Function to these types.

import '../entities/app_language.dart';
import '../entities/content_translation.dart';
import '../entities/onboarding_answer.dart';
import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/track_recommendation.dart';

abstract interface class AiRepository {
  /// Sends the user's onboarding answers to Kimi3 and returns a full
  /// track recommendation with natural-language reasoning, written in
  /// [language].
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
    required AppLanguage language,
  });

  /// Generates a personalized daily brief for the dashboard, written in
  /// [language].
  ///
  /// The result is cached for 24 hours in `ai_profile_insights` to avoid
  /// calling the LLM on every dashboard navigation. Cached separately per
  /// language, so switching Settings language does not surface a stale
  /// brief in the old one.
  Future<String> generateDailyBrief({
    required String userId,
    required String trackSlug,
    required String? experienceLevelSlug,
    required String? learningGoalSlug,
    required int completedTopics,
    required int totalTopics,
    required AppLanguage language,
  });

  /// Generates a Socratic hint for a lab challenge without revealing the
  /// answer, written in [language].
  ///
  /// [attemptCount] controls the verbosity of the hint: after 3 failed
  /// attempts the hint becomes more explicit, but still never gives the answer.
  Future<String> generateLabHint({
    required String challengeQuestion,
    required String challengeType,
    required int attemptCount,
    required String? userContext,
    required AppLanguage language,
  });

  /// Generates a short motivational coaching message for the roadmap header,
  /// personalized to the user's current progress and goal, written in
  /// [language].
  Future<String> generateRoadmapCoachMessage({
    required String trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required String? nextTopicTitle,
    required AppLanguage language,
  });

  /// Generates a short personalized welcome-back headline for the dashboard,
  /// written in [language].
  ///
  /// Cached ~12h server-side per language, same reasoning as
  /// [generateRoadmapCoachMessage].
  Future<String> generateWelcomeMessage({
    required String displayName,
    required String? trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required AppLanguage language,
  });

  /// Translates a batch of topics (title/description) into [language].
  ///
  /// English is the seeded source of truth: this must only be called when
  /// [language] is not English. Topics that fail to translate (Kimi error,
  /// not found) are simply absent from the returned map — the caller falls
  /// back to the English title/description it already has for that id.
  ///
  /// The result is cached server-side in `content_translations`, shared
  /// across every user: the same topic translates to the same Spanish text
  /// for everyone, so it is generated once, not once per user.
  Future<Map<String, TopicTranslation>> translateTopics({
    required List<String> topicIds,
    required AppLanguage language,
  });

  /// Translates a batch of theory challenges (question/blocks/keyTakeaway)
  /// into [language]. Code blocks are preserved verbatim.
  ///
  /// Same caching and degradation behavior as [translateTopics]. Only
  /// `TheoryChallenge` ids should be passed in — exercises are never
  /// translated, since their `content` also encodes the graded answer.
  Future<Map<String, TheoryTranslation>> translateTheoryChallenges({
    required List<String> challengeIds,
    required AppLanguage language,
  });

  /// Translates a batch of exercises (`MultipleChoiceChallenge`,
  /// `FillBlankChallenge`, `OrderLogicChallenge`) into [language].
  ///
  /// Only prose is translated — question/description, and for
  /// multiple_choice/order_logic the option/block text by value, never by
  /// the id that decides the graded answer. fill_blank's code fields are
  /// never sent for translation. Same caching and degradation behavior as
  /// [translateTopics].
  Future<Map<String, ExerciseTranslation>> translateExerciseChallenges({
    required List<String> challengeIds,
    required AppLanguage language,
  });
}
