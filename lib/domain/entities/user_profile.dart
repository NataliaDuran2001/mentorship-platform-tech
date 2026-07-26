// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Perfil de la usuaria: identidad más el resultado del onboarding. Reemplaza
// a la `UserEntity{id, name}` del scaffold original (issue #8).
//
// Los tres campos del onboarding son nulables porque el perfil se crea vacío
// al registrarse (trigger sobre `auth.users`, issue #7) y se va llenando paso
// a paso. `onboardingCompletedAt` es lo que distingue un perfil a medio
// llenar de uno terminado, y es el dato que leen los route guards.

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

  /// Mismo identificador que `auth.users.id`.
  final String id;
  final String email;

  /// Nombre para mostrar. Opcional: el registro por correo no lo pide.
  final String? displayName;

  final ExperienceLevel? experienceLevel;
  final RoadmapTrack? track;
  final LearningGoal? learningGoal;

  /// Momento en que se completó el onboarding, o `null` si sigue pendiente.
  final DateTime? onboardingCompletedAt;

  /// El onboarding está terminado.
  ///
  /// Exige track además de la marca de tiempo: sin track no hay roadmap que
  /// mostrar, y dejar entrar al dashboard en ese estado rompe el CA 1.3.
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
