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
          continueLabel: esResumen ? 'Entrar al Dashboard' : 'Continuar',
          onBack: canGoBack.value ? goToPreviousStep : null,
          onSkip: canSkipCurrentStep.value ? skipCurrentStep : null,
          // En el paso del track «Continuar» queda deshabilitado hasta que haya
          // una selección; en el resumen guarda y sale.
          onContinue: canAdvance.value
              ? (esResumen ? submitOnboarding : goToNextStep)
              : null,
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
        // Lo construye el issue #12. Hasta entonces el aviso es honesto: no un
        // stub que finja funcionar.
        return const _PasoPendiente();
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

  String _tituloDe(OnboardingStepId paso) {
    switch (paso) {
      case OnboardingStepId.level:
        return '¡Hola! ¿Cómo te identificás hoy?';
      case OnboardingStepId.track:
        return '¿Cuál es tu especialidad?';
      case OnboardingStepId.quiz:
        return '¿Qué tipo de problemas te entusiasma más resolver?';
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
        return 'Tu respuesta nos ayuda a trazar tu ruta de aprendizaje ideal.';
      case OnboardingStepId.goal:
        return 'Contanos qué esperás lograr en los próximos 6 meses.';
      case OnboardingStepId.summary:
        return null;
    }
  }
}

/// Aviso del paso que todavía no está construido (cuestionario guía, #12).
class _PasoPendiente extends StatelessWidget {
  const _PasoPendiente();

  @override
  Widget build(BuildContext context) {
    return Text(
      'El cuestionario guía llega con el issue #12. Volvé al paso anterior y '
      'elegí una especialidad.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
