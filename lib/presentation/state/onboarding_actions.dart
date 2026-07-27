// Capa Presentation (State): Acciones del onboarding.
//
// Junto con auth_actions.dart, es el único lugar de `presentation` que toca
// getIt. Los organismos de pasos no saben avanzar ni guardar: avisan qué se
// eligió y estas funciones deciden.
//
// El auto-avance de 400 ms usa `Timer` y no `Future.delayed` a propósito: deja
// claro que es una pausa de interfaz —para que se vea el feedback de selección
// antes de cambiar de paso— y no una petición de red simulada, que es lo que el
// AC2 del issue #9 prohíbe volver a introducir.

import 'dart:async';

import '../../core/di/injection.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/usecases/submit_onboarding_usecase.dart';
import '../utils/auth_error_messages.dart';
import '../utils/constants.dart';
import 'auth_state.dart';
import 'onboarding_state.dart';

Timer? _autoAvance;

/// Elige el nivel de experiencia y avanza.
void selectLevel(ExperienceLevel nivel) {
  selectedLevel.value = nivel;
  _avanzarConFeedback();
}

/// Elige el track y avanza.
///
/// `null` representa «Aún no lo sé»: activa la rama del cuestionario guía, lo
/// que cambia el total de pasos de 4 a 5.
void selectTrack(RoadmapTrack? track) {
  selectedTrack.value = track;
  usesGuidedQuiz.value = track == null;
  _avanzarConFeedback();
}

/// Elige la meta y avanza.
void selectGoal(LearningGoal meta) {
  selectedGoal.value = meta;
  _avanzarConFeedback();
}

/// Avanza al paso siguiente sin esperar.
void goToNextStep() {
  _autoAvance?.cancel();
  if (currentStepIndex.value < totalSteps.value - 1) {
    currentStepIndex.value = currentStepIndex.value + 1;
  }
}

/// Vuelve al paso anterior conservando lo ya elegido.
///
/// No borra ninguna selección: es lo que hace que regresar muestre la opción
/// marcada. Si se vuelve desde el cuestionario guía, sí se desactiva la rama,
/// porque la usuaria está reconsiderando el paso del track.
void goToPreviousStep() {
  _autoAvance?.cancel();
  if (currentStepIndex.value == 0) return;

  final anterior = activeSteps.value[currentStepIndex.value - 1];
  if (currentStep.value == OnboardingStepId.quiz ||
      anterior == OnboardingStepId.quiz) {
    // Se está volviendo al paso del track: se reabre la decisión.
    usesGuidedQuiz.value = false;
    selectedTrack.value = null;
    currentStepIndex.value =
        activeSteps.value.indexOf(OnboardingStepId.track);
    return;
  }

  currentStepIndex.value = currentStepIndex.value - 1;
}

/// Omite el paso actual sin responderlo.
///
/// Solo llega acá desde los pasos omitibles: el pie del onboarding no muestra
/// «Omitir» en los demás. La comprobación está igual, porque una regla que
/// depende de que la UI no ofrezca el botón no es una regla.
void skipCurrentStep() {
  if (!canSkipCurrentStep.value) return;
  goToNextStep();
}

/// Guarda el resultado del onboarding y devuelve `true` si salió bien.
///
/// Sin track no se guarda nada: el caso de uso lo exige por tipos y la base lo
/// exige por constraint, así que llegar acá sin track es un bug, no un estado
/// que haya que tolerar en silencio.
Future<bool> submitOnboarding() async {
  final nivel = selectedLevel.value;
  final track = selectedTrack.value;
  final meta = selectedGoal.value;

  if (track == null) {
    onboardingError.value =
        'Necesitamos saber tu especialidad para armar tu ruta.';
    currentStepIndex.value = activeSteps.value.indexOf(OnboardingStepId.track);
    return false;
  }

  onboardingSaving.value = true;
  onboardingError.value = null;

  try {
    // Nivel y meta van tal como quedaron: si se omitieron, viajan en `null` y
    // se guardan en `null`. Poner un valor por defecto sería inventar datos de
    // la usuaria, y las dos columnas son nulables justamente para esto.
    final perfil = await getIt<SubmitOnboardingUseCase>()(
      track: track,
      experienceLevel: nivel,
      learningGoal: meta,
    );

    // Deja el perfil fresco en el estado para que los route guards dejen pasar
    // al dashboard sin tener que volver a leerlo de la base.
    currentProfile.value = perfil;
    return true;
  } catch (e) {
    onboardingError.value = mensajeDeError(e);
    return false;
  } finally {
    onboardingSaving.value = false;
  }
}

/// Cancela el temporizador pendiente. Para los tests y al salir de la pantalla.
void cancelOnboardingTimers() {
  _autoAvance?.cancel();
  _autoAvance = null;
}

/// Avanza después de una pausa corta, para que se vea la selección.
void _avanzarConFeedback() {
  _autoAvance?.cancel();
  _autoAvance = Timer(AppConstants.durationMedium, goToNextStep);
}
