// Atomic Design (Página): Estructura principal que une organismos y maneja
// la inyección de dependencias y el estado global o de la vista.
//
// Flujo de onboarding del Módulo 1. Vive fuera del shell —sin nav visible—,
// como manda el issue #5.
//
// Es el único nivel que lee el estado del onboarding y llama a sus acciones. Al
// terminar no navega a mano: `submitOnboarding()` deja el perfil completo en
// `currentProfile` y el route guard mueve al dashboard.

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/onboarding_actions.dart';
import '../../state/onboarding_state.dart';
import '../../utils/onboarding_quiz.dart';
import '../organisms/guided_quiz_step.dart';
import '../organisms/onboarding_step_layout.dart';
import '../organisms/onboarding_steps.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (onboardingSaving.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final paso = currentStep.value;
        final esResumen = paso == OnboardingStepId.summary;
        final esCuestionario = paso == OnboardingStepId.quiz;

        // El cuestionario es un solo paso del contador pero tiene navegación
        // interna: el pie maneja sus preguntas en vez del recorrido general.
        final atras = esCuestionario ? goToPreviousQuizQuestion : goToPreviousStep;
        final adelante = esCuestionario
            ? (quizShowingResult.value ? confirmRecommendedTrack : advanceQuiz)
            : (esResumen ? submitOnboarding : goToNextStep);

        return OnboardingStepLayout(
          currentStep: currentStepNumber.value,
          totalSteps: totalSteps.value,
          title: _tituloDe(paso),
          subtitle: _subtituloDe(paso),
          errorMessage: onboardingError.value,
          showBack: canGoBack.value,
          // «Omitir» solo en los pasos omitibles: en el paso 2 desaparece,
          // porque sin track no hay roadmap (CA 1.3).
          showSkip: canSkipCurrentStep.value,
          continueLabel: _etiquetaDeContinuar(paso),
          onBack: canGoBack.value ? atras : null,
          onSkip: canSkipCurrentStep.value ? skipCurrentStep : null,
          // En el paso del track «Continuar» queda deshabilitado hasta que haya
          // una selección; en el resumen guarda y sale.
          onContinue: canAdvance.value ? adelante : null,
          child: _contenidoDe(paso),
        );
      },
    );
  }

  Widget _contenidoDe(OnboardingStepId paso) {
    switch (paso) {
      case OnboardingStepId.level:
        return OnboardingStepRole(
          selected: selectedLevel.value,
          onSelected: selectLevel,
        );
      case OnboardingStepId.track:
        return OnboardingStepStack(
          selected: selectedTrack.value,
          usesGuidedQuiz: usesGuidedQuiz.value,
          onSelected: selectTrack,
          onDontKnow: () => selectTrack(null),
        );
      case OnboardingStepId.quiz:
        final recomendacion = quizRecommendation.value;
        if (quizShowingResult.value && recomendacion != null) {
          return GuidedQuizResult(
            recommendation: recomendacion,
            onConfirm: confirmRecommendedTrack,
            onOverride: overrideRecommendedTrack,
            onRedo: redoQuiz,
          );
        }

        final pregunta = currentQuizQuestion.value;
        return GuidedQuizStep(
          question: pregunta,
          selected: quizAnswers.value[pregunta.number],
          onSelected: answerQuizQuestion,
        );
      case OnboardingStepId.goal:
        return OnboardingStepGoal(
          selected: selectedGoal.value,
          onSelected: selectGoal,
        );
      case OnboardingStepId.summary:
        return OnboardingSummary(
          level: selectedLevel.value,
          track: selectedTrack.value,
          goal: selectedGoal.value,
        );
    }
  }

  /// El botón principal cambia de nombre según lo que hace.
  String _etiquetaDeContinuar(OnboardingStepId paso) {
    if (paso == OnboardingStepId.summary) return 'Entrar al Dashboard';
    if (paso == OnboardingStepId.quiz && quizShowingResult.value) {
      return 'Confirmar esta ruta';
    }
    return 'Continuar';
  }

  String _tituloDe(OnboardingStepId paso) {
    switch (paso) {
      case OnboardingStepId.level:
        return '¡Hola! ¿Cómo te identificás hoy?';
      case OnboardingStepId.track:
        return '¿Cuál es tu especialidad?';
      case OnboardingStepId.quiz:
        return quizShowingResult.value
            ? 'Encontramos tu ruta'
            : currentQuizQuestion.value.prompt;
      case OnboardingStepId.goal:
        return '¿Cuál es tu meta principal?';
      case OnboardingStepId.summary:
        // El resumen trae su propio encabezado con el ícono de confirmación.
        return '';
    }
  }

  String? _subtituloDe(OnboardingStepId paso) {
    switch (paso) {
      case OnboardingStepId.level:
        return 'Queremos personalizar tu experiencia según tu nivel actual.';
      case OnboardingStepId.track:
        return 'Elegí el área donde te sentís más cómoda o donde querés crecer. '
            'Si todavía no lo sabés, te ayudamos.';
      case OnboardingStepId.quiz:
        if (quizShowingResult.value) {
          return 'Podés aceptarla o elegir otra: la decisión final es tuya.';
        }
        final pregunta = currentQuizQuestion.value;
        return 'Pregunta ${pregunta.number} de '
            '${preguntasDelCuestionario.length}. ${pregunta.subtitle}';
      case OnboardingStepId.goal:
        return 'Contanos qué esperás lograr en los próximos 6 meses.';
      case OnboardingStepId.summary:
        return null;
    }
  }
}

