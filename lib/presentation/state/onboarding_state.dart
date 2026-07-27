// Capa Presentation (State): Estado del onboarding con signals.
//
// Solo declara señales y derivados; quien las cambia es onboarding_actions.dart.
//
// La idea central es que el flujo tiene **dos ramas** y por lo tanto un total de
// pasos variable: 4 si la usuaria elige su track directamente, 5 si elige «Aún
// no lo sé» y pasa por el cuestionario guía. En vez de repartir esa cuenta por
// la UI, se declara la lista de pasos activos y todo lo demás se deriva de ella:
// el contador, la barra de progreso y qué paso mostrar. De ahí venía la
// discrepancia entre los dos mockups del prototipo.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';

/// Los pasos posibles. `quiz` solo participa en la rama guiada.
enum OnboardingStepId { level, track, quiz, goal, summary }

/// La usuaria eligió «Aún no lo sé» en el paso 2 y va por el cuestionario guía.
final usesGuidedQuiz = signal<bool>(false);

/// Índice dentro de [activeSteps], empezando en 0.
final currentStepIndex = signal<int>(0);

final selectedLevel = signal<ExperienceLevel?>(null);
final selectedTrack = signal<RoadmapTrack?>(null);
final selectedGoal = signal<LearningGoal?>(null);

/// Guardando el resultado final.
final onboardingSaving = signal<bool>(false);

/// Mensaje de error en español, ya traducido.
final onboardingError = signal<String?>(null);

/// Los pasos que realmente se recorren, en orden.
///
/// Es la única definición del recorrido: el contador, la barra y el enrutado
/// interno se derivan de acá, así que no pueden discrepar entre sí.
final activeSteps = computed<List<OnboardingStepId>>(() {
  return usesGuidedQuiz.value
      ? const [
          OnboardingStepId.level,
          OnboardingStepId.track,
          OnboardingStepId.quiz,
          OnboardingStepId.goal,
          OnboardingStepId.summary,
        ]
      : const [
          OnboardingStepId.level,
          OnboardingStepId.track,
          OnboardingStepId.goal,
          OnboardingStepId.summary,
        ];
});

/// 4 en la rama directa, 5 en la guiada. Incluye el resumen, igual que el
/// «Paso 1 de 4» del prototipo.
final totalSteps = computed(() => activeSteps.value.length);

/// Paso actual. Recorta el índice por si la lista se acortó al volver de la
/// rama guiada a la directa.
final currentStep = computed<OnboardingStepId>(() {
  final pasos = activeSteps.value;
  final indice = currentStepIndex.value.clamp(0, pasos.length - 1);
  return pasos[indice];
});

/// Número visible del paso, empezando en 1.
final currentStepNumber = computed(
  () => currentStepIndex.value.clamp(0, totalSteps.value - 1) + 1,
);

/// Fracción para la barra de progreso, sobre el total real de pasos.
final onboardingProgress =
    computed(() => currentStepNumber.value / totalSteps.value);

/// Se puede volver atrás.
final canGoBack = computed(() => currentStepIndex.value > 0);

/// Se puede omitir el paso actual.
///
/// Solo el nivel y la meta. El track **no** es omitible: sin track no hay
/// roadmap que desplegar y se violaría el CA 1.3. El cuestionario guía tampoco,
/// porque existe justamente para conseguir ese track.
final canSkipCurrentStep = computed(() {
  switch (currentStep.value) {
    case OnboardingStepId.level:
    case OnboardingStepId.goal:
      return true;
    case OnboardingStepId.track:
    case OnboardingStepId.quiz:
    case OnboardingStepId.summary:
      return false;
  }
});

/// El paso actual tiene una respuesta que permita avanzar.
///
/// En el paso del track exige una selección real: es lo que deshabilita
/// «Continuar» hasta que haya track.
final canAdvance = computed(() {
  switch (currentStep.value) {
    case OnboardingStepId.level:
    case OnboardingStepId.goal:
    case OnboardingStepId.summary:
      return true;
    case OnboardingStepId.track:
    case OnboardingStepId.quiz:
      return selectedTrack.value != null;
  }
});

/// Deja el flujo como recién empezado. Se llama al salir del onboarding.
void resetOnboarding() {
  usesGuidedQuiz.value = false;
  currentStepIndex.value = 0;
  selectedLevel.value = null;
  selectedTrack.value = null;
  selectedGoal.value = null;
  onboardingSaving.value = false;
  onboardingError.value = null;
}
