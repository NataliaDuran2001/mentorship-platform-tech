// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The user's profile: identity plus the onboarding result. It replaces the
// `UserEntity{id, name}` of the original scaffold (issue #8).
//
// The three onboarding fields are nullable because the profile is created
// empty on sign-up (trigger on `auth.users`, issue #7) and is filled in step
// by step. `onboardingCompletedAt` is what tells a half-filled profile from a
// finished one, and it is the value the route guards read.

import 'experience_level.dart';
import 'learning_goal.dart';
import 'roadmap_track.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.experienceLevel,
    this.track,
    this.learningGoal,
    this.onboardingCompletedAt,
  });

  /// Same identifier as `auth.users.id`.
  final String id;
  final String email;

  /// Display name. Optional: email sign-up does not ask for it.
  final String? displayName;

  final ExperienceLevel? experienceLevel;
  final RoadmapTrack? track;
  final LearningGoal? learningGoal;

  /// When the onboarding was completed, or `null` if it is still pending.
  final DateTime? onboardingCompletedAt;

  /// The onboarding is finished.
  ///
  /// It requires a track on top of the timestamp: without a track there is no
  /// roadmap to show, and letting the user into the dashboard in that state
  /// breaks AC 1.3.
  bool get hasCompletedOnboarding =>
      onboardingCompletedAt != null && track != null;

  UserProfile copyWith({
    String? displayName,
    ExperienceLevel? experienceLevel,
    RoadmapTrack? track,
    LearningGoal? learningGoal,
    DateTime? onboardingCompletedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      track: track ?? this.track,
      learningGoal: learningGoal ?? this.learningGoal,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }
}
