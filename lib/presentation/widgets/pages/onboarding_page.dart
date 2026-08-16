// Atomic Design (Page): Main structure that wires organisms together and
// handles dependency injection and the global or view state.
//
// Module 1 onboarding flow. It lives outside the shell —with no visible nav—,
// as issue #5 requires.
//
// It is the only level that reads the onboarding state and calls its actions.
// When it ends it does not navigate by hand: `submitOnboarding()` leaves the
// completed profile in `currentProfile` and the route guard moves to the
// dashboard.

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/onboarding_actions.dart';
import '../../state/onboarding_state.dart';
import '../../utils/onboarding_quiz.dart';
import '../../utils/translate.dart';
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

        final step = currentStep.value;
        final isSummary = step == OnboardingStepId.summary;
        final isQuiz = step == OnboardingStepId.quiz;

        // The quiz is a single step of the counter but it has its own internal
        // navigation: the footer drives its questions instead of the overall
        // flow.
        final back = isQuiz ? goToPreviousQuizQuestion : goToPreviousStep;
        final forward = isQuiz
            ? (quizShowingResult.value ? confirmRecommendedTrack : advanceQuiz)
            : (isSummary ? submitOnboarding : goToNextStep);

        return OnboardingStepLayout(
          currentStep: currentStepNumber.value,
          totalSteps: totalSteps.value,
          title: _titleOf(step),
          subtitle: _subtitleOf(step),
          errorMessage: onboardingError.value,
          showBack: canGoBack.value,
          // "Skip" only on the skippable steps: on step 2 it disappears,
          // because without a track there is no roadmap (AC 1.3).
          showSkip: canSkipCurrentStep.value,
          continueLabel: _continueLabelOf(step),
          onBack: canGoBack.value ? back : null,
          onSkip: canSkipCurrentStep.value ? skipCurrentStep : null,
          // On the track step "Continue" stays disabled until there is a
          // selection; on the summary it saves and leaves.
          onContinue: canAdvance.value ? forward : null,
          child: _contentOf(step),
        );
      },
    );
  }

  Widget _contentOf(OnboardingStepId step) {
    switch (step) {
      case OnboardingStepId.language:
        return OnboardingStepLanguage(
          selected: selectedLanguage.value,
          onSelected: selectLanguage,
        );
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
        final recommendation = quizRecommendation.value;
        if (quizShowingResult.value && recommendation != null) {
          return GuidedQuizResult(
            recommendation: recommendation,
            onConfirm: confirmRecommendedTrack,
            onOverride: overrideRecommendedTrack,
            onRedo: redoQuiz,
          );
        }

        final question = currentQuizQuestion.value;
        return GuidedQuizStep(
          question: question,
          selected: quizAnswers.value[question.number],
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

  /// The main button changes its name depending on what it does.
  String _continueLabelOf(OnboardingStepId step) {
    if (step == OnboardingStepId.summary) {
      return tr('Go to Dashboard', 'Ir al Panel');
    }
    if (step == OnboardingStepId.quiz && quizShowingResult.value) {
      return tr('Confirm this path', 'Confirmar este camino');
    }
    return tr('Continue', 'Continuar');
  }

  String _titleOf(OnboardingStepId step) {
    switch (step) {
      case OnboardingStepId.language:
        // Both languages at once, and not `tr()`: this is the screen that
        // decides which language `tr()` will answer in, so it has to be
        // readable before that decision exists.
        return 'Elige tu idioma\nChoose your language';
      case OnboardingStepId.level:
        return tr(
          'Hi! How would you describe yourself today?',
          '¡Hola! ¿Cómo te describirías hoy?',
        );
      case OnboardingStepId.track:
        return tr(
          'What do you want to focus on?',
          '¿En qué te quieres enfocar?',
        );
      case OnboardingStepId.quiz:
        return quizShowingResult.value
            ? tr('We found your path', 'Encontramos tu camino')
            : currentQuizQuestion.value.prompt;
      case OnboardingStepId.goal:
        return tr('What is your main goal?', '¿Cuál es tu meta principal?');
      case OnboardingStepId.summary:
        // The summary brings its own header with the confirmation icon.
        return '';
    }
  }

  String? _subtitleOf(OnboardingStepId step) {
    switch (step) {
      case OnboardingStepId.language:
        return 'Verás el resto de la aplicación en el idioma que elijas. '
            'Puedes cambiarlo cuando quieras desde tu perfil.\n'
            "You'll see the rest of the app in the language you pick. "
            'You can change it any time from your profile.';
      case OnboardingStepId.level:
        return tr(
          'We want to tailor your experience to your current level.',
          'Queremos ajustar tu experiencia a tu nivel actual.',
        );
      case OnboardingStepId.track:
        return tr(
          'Choose the area where you feel most at home, or where you '
              'want to grow. If you are not sure yet, we will help you.',
          'Elige el área donde te sientas más cómoda, o donde quieras '
              'crecer. Si todavía no estás segura, te ayudamos.',
        );
      case OnboardingStepId.quiz:
        if (quizShowingResult.value) {
          return tr(
            'You can take it or pick another one: the final call is '
                'yours.',
            'Puedes aceptarlo o elegir otro: la decisión final es '
                'tuya.',
          );
        }
        final question = currentQuizQuestion.value;
        return tr(
          'Question ${question.number} of '
              '${quizQuestions.length}. ${question.subtitle}',
          'Pregunta ${question.number} de '
              '${quizQuestions.length}. ${question.subtitle}',
        );
      case OnboardingStepId.goal:
        return tr(
          'Tell us what you want to achieve in the next 6 months.',
          'Cuéntanos qué quieres lograr en los próximos 6 meses.',
        );
      case OnboardingStepId.summary:
        return null;
    }
  }
}
