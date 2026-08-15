// Domain layer: Contract (interface) of the onboarding repository.
// It defines WHAT can be done, not HOW. The implementation lives in `data`.

import '../entities/app_language.dart';
import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/onboarding_answer.dart';
import '../entities/roadmap_track.dart';
import '../entities/user_profile.dart';

abstract class OnboardingRepository {
  /// Saves an answer of the authenticated user, the moment it is selected and
  /// not at the end of the flow (issue #14).
  ///
  /// It is an upsert by (user, `stepKey`): going back and changing an answer
  /// updates the existing row instead of adding another one.
  Future<void> saveAnswer(OnboardingAnswer answer);

  /// Answers already saved by the authenticated user. Empty list if she has
  /// not started. It is the basis of resuming: the flow picks up at the first
  /// unanswered step, with the previous ones already marked.
  Future<List<OnboardingAnswer>> loadAnswers();

  /// Profile of the authenticated user, or `null` if there is no session.
  Future<UserProfile?> loadProfile();

  /// Marks the onboarding as completed and persists the result in the
  /// profile.
  ///
  /// The track is required and non-nullable on purpose: without a track there
  /// is no roadmap to show (AC 1.3), and no path may leave the profile
  /// complete with a null `track_id`.
  ///
  /// The level and the goal **are** nullable, because their steps can be
  /// skipped and skipping cannot translate into a made-up value: they are
  /// stored as `null` and can be filled in later from the profile.
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  });

  /// Updates the Settings language for the authenticated user and returns
  /// the resulting profile.
  Future<UserProfile> updateLanguage({required AppLanguage language});
}
