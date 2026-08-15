// Data layer: Model that parses the information from/to the database and maps
// to the UserProfile entity of the Domain layer.
//
// The keys are the column names of `public.profiles`, exactly as the migration
// of issue #7 created them. The values of `experience_level`, `track_id`,
// `learning_goal` and `language` are the slugs of the `domain` enums, so the
// mapping is direct and does not need a translation table.

import '../../domain/entities/app_language.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.role,
    this.experienceLevel,
    this.trackId,
    this.learningGoal,
    this.onboardingCompletedAt,
    this.language,
  });

  /// Columns requested in a `select`. Explicit and not `*` so that adding a
  /// column to the table does not silently change what travels to the
  /// client.
  static const String columns =
      'id, email, display_name, role, experience_level, track_id, '
      'learning_goal, onboarding_completed_at, language';

  final String id;
  final String email;
  final String? displayName;
  final String? role;
  final String? experienceLevel;
  final String? trackId;
  final String? learningGoal;
  final DateTime? onboardingCompletedAt;
  final String? language;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      // The trigger copies the email from auth.users, so in practice it is
      // never null; the fallback keeps an old row from breaking the read.
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      role: json['role'] as String?,
      experienceLevel: json['experience_level'] as String?,
      trackId: json['track_id'] as String?,
      learningGoal: json['learning_goal'] as String?,
      onboardingCompletedAt: _parseDate(json['onboarding_completed_at']),
      language: json['language'] as String?,
    );
  }

  factory UserModel.fromEntity(UserProfile profile) {
    return UserModel(
      id: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      role: profile.role.slug,
      experienceLevel: profile.experienceLevel?.slug,
      trackId: profile.track?.slug,
      learningGoal: profile.learningGoal?.slug,
      onboardingCompletedAt: profile.onboardingCompletedAt,
      language: profile.language.slug,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      role: UserRole.fromSlug(role),
      // An unknown slug is read as null instead of breaking: a row written by
      // a newer version of the app must not leave the user unable to get in.
      experienceLevel: ExperienceLevel.fromSlug(experienceLevel),
      track: RoadmapTrack.fromSlug(trackId),
      learningGoal: LearningGoal.fromSlug(learningGoal),
      onboardingCompletedAt: onboardingCompletedAt,
      // Unknown/missing slug reads as English, the app's original baseline.
      language: AppLanguage.fromSlug(language),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'experience_level': experienceLevel,
      'track_id': trackId,
      'learning_goal': learningGoal,
      'onboarding_completed_at': onboardingCompletedAt?.toIso8601String(),
      'language': language,
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }
}
