// Capa Domain: Contrato (interfaz) del repositorio de onboarding.
// Define QUÉ se puede hacer, no CÓMO. La implementación vive en `data`.

import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/onboarding_answer.dart';
import '../entities/roadmap_track.dart';
import '../entities/user_profile.dart';

abstract class OnboardingRepository {
  /// Guarda una respuesta de la usuaria autenticada, al momento de
  /// seleccionarla y no al final del flujo (issue #14).
  ///
  /// Es un upsert por (usuaria, `stepKey`): volver atrás y cambiar una
  /// respuesta actualiza la fila existente en vez de agregar otra.
  Future<void> saveAnswer(OnboardingAnswer answer);

  /// Respuestas ya guardadas de la usuaria autenticada. Lista vacía si no
  /// empezó. Es la base de la reanudación: el flujo retoma en el primer paso
  /// sin responder, con lo anterior ya marcado.
  Future<List<OnboardingAnswer>> loadAnswers();

  /// Perfil de la usuaria autenticada, o `null` si no hay sesión.
  Future<UserProfile?> loadProfile();

  /// Marca el onboarding como completado y persiste el resultado en el perfil.
  ///
  /// El track es obligatorio y no nulable a propósito: sin track no hay
  /// roadmap que mostrar (CA 1.3), y ningún camino puede dejar el perfil
  /// completo con `track_id` nulo.
  Future<UserProfile> completeOnboarding({
    required ExperienceLevel experienceLevel,
    required RoadmapTrack track,
    required LearningGoal learningGoal,
  });
}
