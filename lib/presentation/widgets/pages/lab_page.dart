import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/entities/lab_challenge.dart';
import '../../state/content_translation_state.dart';
import '../../state/lab_actions.dart';
import '../../state/lab_state.dart';
import '../../state/ai_state.dart';
import '../../state/ai_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../organisms/lab_fill_blank.dart';
import '../organisms/lab_multiple_choice.dart';
import '../organisms/lab_order_logic.dart';
import '../organisms/lab_score_card.dart';
import '../organisms/lab_theory.dart';

class LabPage extends StatefulWidget {
  const LabPage({super.key, required this.topicId});

  final String topicId;

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  @override
  void initState() {
    super.initState();
    // Start loading on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadLabs(widget.topicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.go('/path'),
              tooltip: tr('Exit Lab', 'Salir del laboratorio'),
            ),
            title: Text(tr('Interactive Lab', 'Laboratorio interactivo')),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: SignalBuilder(
                builder: (context) {
                  if (labChallenges.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final progress =
                      (labCurrentIndex.value) / labChallenges.value.length;
                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),
          body: SignalBuilder(
            builder: (context) {
              if (labLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (labError.value != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text(
                        labError.value!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      ElevatedButton(
                        onPressed: () => loadLabs(widget.topicId),
                        child: Text(tr('Retry', 'Reintentar')),
                      ),
                    ],
                  ),
                );
              }

              if (labIsCompleted.value) {
                return _CompletedView();
              }

              final challenge = labCurrentChallenge.value;
              if (challenge == null) {
                return Center(
                  child: Text(
                    tr('No challenges available.', 'No hay retos disponibles.'),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.spacingLg),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppConstants.maxReadableWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildChallengeWidget(challenge),
                              // There is nothing to hint at on an explanation:
                              // the answer is the text the learner is reading.
                              if (challenge is! TheoryChallenge)
                                _AiHintSection(
                                  topicId: widget.topicId,
                                  challenge: challenge,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _BottomValidationBar(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChallengeWidget(LabChallenge challenge) {
    if (challenge is TheoryChallenge) {
      return LabTheory(
        challenge: challenge,
        translation: labTheoryTranslations.value[challenge.id],
      );
    } else if (challenge is MultipleChoiceChallenge) {
      return LabMultipleChoice(
        challenge: challenge,
        translation: labExerciseTranslations.value[challenge.id],
      );
    } else if (challenge is FillBlankChallenge) {
      return LabFillBlank(
        challenge: challenge,
        translation: labExerciseTranslations.value[challenge.id],
      );
    } else if (challenge is OrderLogicChallenge) {
      return LabOrderLogic(
        challenge: challenge,
        translation: labExerciseTranslations.value[challenge.id],
      );
    }
    return Text(tr('Unknown challenge type', 'Tipo de reto desconocido'));
  }
}

class _BottomValidationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final isValid = labIsCurrentValid.value;
        final hasSelection = labSelectedAnswers.value.isNotEmpty;
        // An explanation has no right or wrong answer, so it gets neither the
        // check nor the feedback colors: acknowledging it is the whole
        // interaction.
        final isTheory = labCurrentChallenge.value is TheoryChallenge;

        Color barColor = AppColors.surfaceContainerLowest;
        if (isValid == true) barColor = AppColors.successContainer;
        if (isValid == false) barColor = AppColors.errorContainer;

        if (isTheory) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: nextLabChallenge,
                    icon: const Icon(Icons.check),
                    label: Text(tr('Got it', 'Entendido')),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          decoration: BoxDecoration(
            color: barColor,
            border: const Border(
              top: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(child: _FeedbackMessage(isValid: isValid)),
                const SizedBox(width: AppConstants.spacingMd),
                if (isValid == true)
                  ElevatedButton(
                    onPressed: nextLabChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.onSuccess,
                    ),
                    child: Text(tr('Continue', 'Continuar')),
                  )
                else
                  ElevatedButton(
                    onPressed: hasSelection ? submitLabAnswer : null,
                    child: Text(tr('Check Answer', 'Verificar respuesta')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({required this.isValid});
  final bool? isValid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isValid == null) {
      return const SizedBox.shrink();
    }

    if (isValid == true) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.onSuccessContainer),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              tr('Excellent! That is correct.', '¡Excelente! Es correcto.'),
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.onSuccessContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.cancel, color: AppColors.onErrorContainer),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Text(
            tr(
              'Not quite right. Try again.',
              'No es del todo correcto. Intenta de nuevo.',
            ),
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SignalBuilder(
      builder: (context) {
        final saveError = labSaveError.value;
        final score = labScore.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxReadableWidth,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: AppConstants.iconSizeCelebration,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  Text(
                    tr('Lab Completed!', '¡Laboratorio completado!'),
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  // A section made only of explanations would score a full
                  // house for reading, and calling that a perfect run would
                  // congratulate something that was never at stake.
                  if (score.hasExercises)
                    LabScoreCard(
                      score: score,
                      missedQuestions: labMissedQuestions.value,
                    )
                  else
                    Text(
                      tr(
                        'You worked through every step here. Nice work!',
                        '¡Recorriste todos los pasos de aquí. Buen trabajo!',
                      ),
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  // The topic is closed here, so the path is left up to date
                  // before going back to it. While it is being recorded the way
                  // out is held, otherwise the tree would be reached still
                  // showing the topic as pending.
                  if (labSavingProgress.value) ...[
                    const SizedBox(height: AppConstants.spacingXl),
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      tr('Saving your progress…', 'Guardando tu progreso…'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ] else if (saveError != null) ...[
                    const SizedBox(height: AppConstants.spacingLg),
                    Text(
                      '$saveError ${tr("Your answers are safe, but the topic wasn't marked as completed.", 'Tus respuestas están a salvo, pero el tema no quedó marcado como completado.')}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    ElevatedButton(
                      onPressed: completeCurrentTopic,
                      child: Text(tr('Retry', 'Reintentar')),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => context.go('/path'),
                      child: Text(
                        tr('Return to my path', 'Volver a mi camino'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppConstants.spacingXl),
                    ElevatedButton(
                      onPressed: () => context.go('/path'),
                      child: Text(
                        tr('Return to my path', 'Volver a mi camino'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AiHintSection extends StatelessWidget {
  const _AiHintSection({required this.topicId, required this.challenge});

  final String topicId;
  final LabChallenge challenge;

  String _challengeType(LabChallenge challenge) {
    if (challenge is MultipleChoiceChallenge) return 'multiple_choice';
    if (challenge is FillBlankChallenge) return 'fill_blank';
    if (challenge is OrderLogicChallenge) return 'order_logic';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final hintsList = labHints.value[topicId] ?? const <String>[];
        final textTheme = Theme.of(context).textTheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.spacingLg),
            const Divider(),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      tr('Need a Hint?', '¿Necesitas una pista?'),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (labHintLoading.value)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      requestLabHint(
                        topicId,
                        challenge.question,
                        _challengeType(challenge),
                      );
                    },
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(
                      hintsList.isEmpty
                          ? tr('Get Hint', 'Obtener pista')
                          : tr('Get Another Hint', 'Obtener otra pista'),
                    ),
                  ),
              ],
            ),
            if (labHintError.value != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                tr(
                  'Could not load hint. Try again.',
                  'No pudimos cargar la pista. Intenta de nuevo.',
                ),
                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            if (hintsList.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < hintsList.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💡 ', style: textTheme.bodyMedium),
                            Expanded(
                              child: Text(
                                hintsList[i],
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
