// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The user's profile: identity plus the onboarding result. It replaces the
// `UserEntity{id, name}` of the original scaffold (issue #8).
//
// The three onboarding fields are nullable because the profile is created
// empty on sign-up (trigger on `auth.users`, issue #7) and is filled in step
// by step. `onboardingCompletedAt` is what tells a half-filled profile from a
// finished one, and it is the value the route guards read.

import 'app_language.dart';
import 'experience_level.dart';
import 'learning_goal.dart';
import 'roadmap_track.dart';
import 'user_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.role = UserRole.student,
    this.experienceLevel,
    this.track,
    this.learningGoal,
    this.onboardingCompletedAt,
    this.language = AppLanguage.en,
  });

  /// Same identifier as `auth.users.id`.
  final String id;
  final String email;

  /// Display name. Optional: email sign-up does not ask for it.
  final String? displayName;

  /// What the user is (issue #36). Everybody signs up as a student; an admin
  /// is promoted from outside the app, on purpose.
  ///
  /// Never use it as the only gate on a write: the database policies are what
  /// actually enforce this. Here it is for showing or hiding the admin parts
  /// of the UI once they exist.
  final UserRole role;

  final ExperienceLevel? experienceLevel;
  final RoadmapTrack? track;
  final LearningGoal? learningGoal;

  /// When the onboarding was completed, or `null` if it is still pending.
  final DateTime? onboardingCompletedAt;

  /// The language the student picked in Settings. Drives both the app's UI
  /// text and the language the AI Edge Functions answer in.
  final AppLanguage language;

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
    AppLanguage? language,
  }) {
    return UserProfile(
      id: id,
      email: email,
      // The role is not a parameter of copyWith on purpose: it cannot be
      // changed from the client, so offering a way to "change" it here would
      // only build something the database rejects.
      role: role,
      displayName: displayName ?? this.displayName,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      track: track ?? this.track,
      learningGoal: learningGoal ?? this.learningGoal,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      language: language ?? this.language,
    );
  }
}
