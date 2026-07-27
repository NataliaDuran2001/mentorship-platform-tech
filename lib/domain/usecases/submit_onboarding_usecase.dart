// Domain layer: Use case encapsulating one business rule of the app.
//
// Closing of the onboarding: it persists level, track and goal, and marks the
// profile as completed.

import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/roadmap_track.dart';
import '../entities/user_profile.dart';
import '../repositories/onboarding_repository.dart';

class SubmitOnboardingUseCase {
  const SubmitOnboardingUseCase(this.repository);

  final OnboardingRepository repository;

  /// The track is required: the type makes it impossible to omit, which is
  /// exactly the guarantee AC 1.3 asks for (no track, no roadmap). That is
  /// why "Skip" is forbidden in onboarding step 2.
  ///
  /// The level and the goal arrive nullable because their steps can indeed be
  /// skipped, and skipping is stored as `null`, not as a made-up default
  /// value.
  Future<UserProfile> call({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) {
    return repository.completeOnboarding(
      track: track,
      experienceLevel: experienceLevel,
      learningGoal: learningGoal,
    );
  }
}
