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
import '../../domain/entities/onboarding_answer.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/recommend_track_usecase.dart';
import '../../domain/usecases/submit_onboarding_usecase.dart';
import '../utils/auth_error_messages.dart';
import '../utils/constants.dart';
import '../utils/onboarding_quiz.dart';
import 'auth_state.dart';
import 'onboarding_state.dart';

Timer? _autoAvance;

/// Elige el nivel de experiencia y avanza.
///
/// La respuesta se persiste **al elegirla**, no al final del flujo: es lo que
/// hace reanudable el onboarding (issue #14).
void selectLevel(ExperienceLevel nivel) {
  selectedLevel.value = nivel;
  _persistirRespuesta(OnboardingKeys.experienceLevel, nivel.slug);
  _avanzarConFeedback();
}

/// Elige el track y avanza.
///
/// `null` representa «Aún no lo sé»: activa la rama del cuestionario guía, lo
/// que cambia el total de pasos de 4 a 5.
void selectTrack(RoadmapTrack? track) {
  selectedTrack.value = track;
  usesGuidedQuiz.value = track == null;
  // «Aún no lo sé» también se guarda: al reanudar hay que saber que la usuaria
  // pidió la guía, no que dejó el paso sin responder.
  _persistirRespuesta(
    OnboardingKeys.track,
    track?.slug ?? OnboardingKeys.unknownTrackValue,
  );
  _avanzarConFeedback();
}

/// Elige la meta y avanza.
void selectGoal(LearningGoal meta) {
  selectedGoal.value = meta;
  _persistirRespuesta(OnboardingKeys.goal, meta.slug);
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

  // Omitir deja rastro. Sin él, reanudar devolvería a la usuaria a un paso que
  // ya decidió saltear, porque una selección en `null` se ve igual que un paso
  // al que nunca llegó.
  final clave = _claveDelPaso(currentStep.value);
  if (clave != null) {
    _persistirRespuesta(clave, OnboardingKeys.skippedValue);
  }

  goToNextStep();
}

/// Clave de `onboarding_answers` del paso, o `null` si el paso no guarda nada.
String? _claveDelPaso(OnboardingStepId paso) {
  switch (paso) {
    case OnboardingStepId.level:
      return OnboardingKeys.experienceLevel;
    case OnboardingStepId.track:
      return OnboardingKeys.track;
    case OnboardingStepId.goal:
      return OnboardingKeys.goal;
    case OnboardingStepId.quiz:
    case OnboardingStepId.summary:
      return null;
  }
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

// ---------------------------------------------------------------------------
// Reanudación (issue #14)
// ---------------------------------------------------------------------------

/// Lee el estado parcial guardado y deja el flujo listo para continuar.
///
/// Se llama al leer el perfil de una usuaria con el onboarding incompleto, o
/// sea antes de que la pantalla se monte. Reanudar es reconstruir dos cosas: las
/// selecciones previas —para que se vean marcadas— y el primer paso sin
/// responder, que es donde hay que aterrizar.
Future<void> restoreOnboarding() async {
  final List<OnboardingAnswer> respuestas;
  try {
    respuestas = await getIt<OnboardingRepository>().loadAnswers();
  } catch (_) {
    // Sin poder leer el estado parcial se empieza de cero, que es el
    // comportamiento anterior al #14: peor experiencia, no un error.
    return;
  }
  if (respuestas.isEmpty) return;

  final porClave = <String, String>{
    for (final r in respuestas) r.stepKey: r.value,
  };
  storedStepKeys.value = porClave.keys.toSet();

  selectedLevel.value =
      ExperienceLevel.fromSlug(porClave[OnboardingKeys.experienceLevel]);
  selectedGoal.value = LearningGoal.fromSlug(porClave[OnboardingKeys.goal]);
  selectedTrack.value = RoadmapTrack.fromSlug(porClave[OnboardingKeys.track]);

  final delCuestionario = _respuestasDelCuestionario(respuestas);
  quizAnswers.value = delCuestionario;

  // La rama guiada se reconoce por cualquiera de dos rastros: el paso 2 guardado
  // como «unknown», o respuestas del cuestionario ya dadas. El segundo importa
  // porque al confirmar la recomendación el paso 2 se sobreescribe con el track
  // real, y sin ese rastro el contador volvería a decir «de 4».
  usesGuidedQuiz.value =
      porClave[OnboardingKeys.track] == OnboardingKeys.unknownTrackValue ||
          delCuestionario.isNotEmpty;

  _situarEnElCuestionario(delCuestionario);
  currentStepIndex.value = _primerPasoSinResponder();
}

Map<int, RoadmapTrack> _respuestasDelCuestionario(
  List<OnboardingAnswer> respuestas,
) {
  final resultado = <int, RoadmapTrack>{};
  for (final r in respuestas) {
    if (!r.stepKey.startsWith(OnboardingKeys.quizPrefix)) continue;
    final numero =
        int.tryParse(r.stepKey.substring(OnboardingKeys.quizPrefix.length));
    final track = RoadmapTrack.fromSlug(r.value);
    if (numero != null && track != null) resultado[numero] = track;
  }
  return resultado;
}

/// Deja el cuestionario en la primera pregunta sin responder, o en el resultado
/// si ya están todas.
void _situarEnElCuestionario(Map<int, RoadmapTrack> respondidas) {
  if (!usesGuidedQuiz.value) return;

  final indice = preguntasDelCuestionario.indexWhere(
    (p) => !respondidas.containsKey(p.number),
  );

  if (indice >= 0) {
    quizQuestionIndex.value = indice;
    quizShowingResult.value = false;
    return;
  }

  // Todas respondidas. Si además falta confirmar el track, se vuelve a mostrar
  // el resultado, recalculado por el caso de uso.
  quizQuestionIndex.value = preguntasDelCuestionario.length - 1;
  if (selectedTrack.value == null) {
    _calcularRecomendacion();
  }
}

/// Índice del primer paso del recorrido que no tiene respuesta.
///
/// Si están todos respondidos, aterriza en el resumen.
int _primerPasoSinResponder() {
  final pasos = activeSteps.value;

  for (var i = 0; i < pasos.length; i++) {
    switch (pasos[i]) {
      case OnboardingStepId.level:
        // Se pregunta por la fila guardada y no por la selección: omitir deja la
        // selección en `null` igual que no haber llegado.
        if (!storedStepKeys.value.contains(OnboardingKeys.experienceLevel)) {
          return i;
        }
      case OnboardingStepId.track:
        // Con la rama guiada activa el paso 2 ya está contestado: la respuesta
        // fue «no lo sé».
        if (selectedTrack.value == null && !usesGuidedQuiz.value) return i;
      case OnboardingStepId.quiz:
        if (selectedTrack.value == null) return i;
      case OnboardingStepId.goal:
        if (!storedStepKeys.value.contains(OnboardingKeys.goal)) return i;
      case OnboardingStepId.summary:
        return i;
    }
  }
  return pasos.length - 1;
}

// ---------------------------------------------------------------------------
// Cuestionario guía (issue #12)
// ---------------------------------------------------------------------------

/// Responde la pregunta visible del cuestionario y avanza.
///
/// La respuesta se persiste al momento de elegirla, no al final: es lo que
/// alimenta la reanudación del #14 y lo que exige el AC5 de este issue.
Future<void> answerQuizQuestion(RoadmapTrack afinidad) async {
  final pregunta = currentQuizQuestion.value;

  // Mapa nuevo y no mutación in situ: un signal compara por identidad y no
  // notificaría si se modifica el mismo mapa.
  quizAnswers.value = <int, RoadmapTrack>{
    ...quizAnswers.value,
    pregunta.number: afinidad,
  };

  await _persistirRespuesta(
    OnboardingKeys.quizQuestion(pregunta.number),
    afinidad.slug,
  );

  _avanzarEnElCuestionarioConFeedback();
}

/// Vuelve a la pregunta anterior del cuestionario, o al paso del track si ya
/// está en la primera.
void goToPreviousQuizQuestion() {
  cancelOnboardingTimers();

  if (quizShowingResult.value) {
    quizShowingResult.value = false;
    return;
  }
  if (quizQuestionIndex.value > 0) {
    quizQuestionIndex.value = quizQuestionIndex.value - 1;
    return;
  }
  // En la primera pregunta, «Anterior» sale del cuestionario.
  goToPreviousStep();
}

/// Avanza a la pregunta siguiente o calcula la recomendación si era la última.
void advanceQuiz() {
  cancelOnboardingTimers();

  if (quizQuestionIndex.value < preguntasDelCuestionario.length - 1) {
    quizQuestionIndex.value = quizQuestionIndex.value + 1;
    return;
  }
  _calcularRecomendacion();
}

/// Acepta el track recomendado y sigue en el paso de la meta.
///
/// `usesGuidedQuiz` se deja en `true` a propósito: el recorrido siguió teniendo
/// 5 pasos y el contador tiene que seguir diciéndolo.
Future<void> confirmRecommendedTrack() async {
  final track = quizRecommendation.value?.track;
  if (track == null) return;
  await _asignarTrackDelCuestionario(track);
}

/// Corrige la recomendación a mano y sigue en el paso de la meta.
Future<void> overrideRecommendedTrack(RoadmapTrack track) =>
    _asignarTrackDelCuestionario(track);

/// Vuelve a las preguntas para responderlas de nuevo.
void redoQuiz() {
  cancelOnboardingTimers();
  quizAnswers.value = <int, RoadmapTrack>{};
  quizQuestionIndex.value = 0;
  quizShowingResult.value = false;
  quizRecommendation.value = null;
}

Future<void> _asignarTrackDelCuestionario(RoadmapTrack track) async {
  selectedTrack.value = track;
  await _persistirRespuesta(OnboardingKeys.track, track.slug);
  goToNextStep();
}

/// La regla de decisión NO está acá: sale del caso de uso del dominio, que es
/// lo que el AC3 de este issue verifica. Este método solo traduce el mapa de
/// respuestas al formato del contrato.
void _calcularRecomendacion() {
  final respuestas = [
    for (final entrada in quizAnswers.value.entries)
      OnboardingAnswer(
        stepKey: OnboardingKeys.quizQuestion(entrada.key),
        value: entrada.value.slug,
      ),
  ];

  quizRecommendation.value = getIt<RecommendTrackUseCase>()(respuestas);
  quizShowingResult.value = true;
}

/// Guarda una respuesta suelta, sin romper el flujo si falla.
///
/// Un fallo de red al guardar no puede frenar el onboarding: la usuaria pierde
/// la reanudación de ese paso, no el paso. El resultado final se persiste igual
/// en `submitOnboarding()`, que sí reporta el error.
Future<void> _persistirRespuesta(String stepKey, String valor) async {
  // Se marca como guardada apenas se intenta: la reanudación de esta sesión no
  // debería depender de que el viaje al backend haya terminado.
  storedStepKeys.value = <String>{...storedStepKeys.value, stepKey};

  try {
    await getIt<OnboardingRepository>().saveAnswer(
      OnboardingAnswer(stepKey: stepKey, value: valor),
    );
  } catch (_) {
    // Silencio deliberado. Ver el comentario de arriba.
  }
}

void _avanzarEnElCuestionarioConFeedback() {
  _autoAvance?.cancel();
  _autoAvance = Timer(AppConstants.durationMedium, advanceQuiz);
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
