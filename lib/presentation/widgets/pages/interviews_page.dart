// Atomic Design (Page): Interview-practice intro screen. Stays inside the
// shell (keeps the bottom-nav destination); starting a session navigates to
// the full-screen `/interviews/session` route.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_state.dart';
import '../../state/interview_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/translate.dart';
import '../atoms/custom_input.dart';

class InterviewsPage extends StatelessWidget {
  const InterviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxReadableWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: SignalBuilder(
            builder: (context) {
              final profile = currentProfile.value;
              final textTheme = Theme.of(context).textTheme;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.record_voice_over_outlined,
                    size: AppConstants.iconSizeCelebration,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  Text(
                    tr(
                      'Practice for your next interview',
                      'Practica para tu próxima entrevista',
                    ),
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    tr(
                      "We'll ask you a few interview questions for your path. "
                          "At the end, you get friendly feedback on all your "
                          'answers. Take your time — this is just practice.',
                      'Te haremos algunas preguntas de entrevista para tu '
                          'camino. Al final, recibes feedback amigable sobre '
                          'todas tus respuestas. Tómate tu tiempo — esto es '
                          'solo práctica.',
                    ),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  if (profile?.track != null) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    _ProfileSummaryChip(
                      trackLabel: trackName(profile!.track)!,
                      levelLabel: levelName(profile.experienceLevel),
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingXl),
                  if (profile?.track == null)
                    Text(
                      tr(
                        'Finish setting up your path first so we can pick the '
                            'right questions for you.',
                        'Termina de configurar tu camino primero para que '
                            'podamos elegir las preguntas correctas para ti.',
                      ),
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr(
                          'What role are you practicing for? (optional)',
                          '¿Para qué puesto te preparas? (opcional)',
                        ),
                        style: textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    CustomInput(
                      hintText: tr(
                        'e.g. Frontend Developer, QA Tester',
                        'ej. Desarrolladora Frontend, QA Tester',
                      ),
                      onChanged: (value) => interviewDesiredRole.value = value,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/interviews/session'),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(tr('Start practice', 'Empezar práctica')),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryChip extends StatelessWidget {
  const _ProfileSummaryChip({required this.trackLabel, this.levelLabel});

  final String trackLabel;
  final String? levelLabel;

  @override
  Widget build(BuildContext context) {
    final label = levelLabel == null ? trackLabel : '$trackLabel · $levelLabel';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
