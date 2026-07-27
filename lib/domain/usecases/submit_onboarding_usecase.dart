// Capa Domain: Caso de uso que encapsula una regla de negocio de la app.
//
// Cierre del onboarding: persiste nivel, track y meta, y marca el perfil como
// completado.

import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/roadmap_track.dart';
import '../entities/user_profile.dart';
import '../repositories/onboarding_repository.dart';

class SubmitOnboardingUseCase {
  const SubmitOnboardingUseCase(this.repository);

  final OnboardingRepository repository;

  /// El track es obligatorio: el tipo lo hace imposible de omitir, que es
  /// justo la garantía que pide el CA 1.3 (sin track no hay roadmap). Por eso
  /// «Omitir» está prohibido en el paso 2 del onboarding.
  ///
  /// El nivel y la meta llegan nulables porque sus pasos sí se pueden omitir, y
  /// omitir se guarda como `null`, no como un valor por defecto inventado.
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
