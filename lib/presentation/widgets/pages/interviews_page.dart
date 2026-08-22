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
                  // History is a detour from the "start a practice" flow, not
                  // a step in it — a lightweight outlined button keeps it
                  // reachable without competing with the primary CTA below.
                  if (profile?.track != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/interviews/history'),
                        icon: const Icon(
                          Icons.history,
                          size: AppConstants.iconSizeSm,
                        ),
                        label: Text(tr('History', 'Historial')),
                      ),
                    ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Text(
                    tr(
                      'Practice for your next interview',
                      'Practica para tu próxima entrevista',
                    ),
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    tr(
                      'A few interview questions, then friendly feedback on '
                          'all your answers.',
                      'Algunas preguntas de entrevista y feedback amigable '
                          'al final.',
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
                  else
                    const _PracticeActionCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Groups the role input and the primary CTA into one hero card, in the
/// same solid-`primary` language as the Dashboard's "Next up" card
/// (`dashboard_page.dart`) — the one full-bleed, high-contrast block this
/// app already uses to mark "the one thing to do right now". Reusing it
/// here instead of another pale bordered box is what makes starting a
/// practice feel like the main event of the screen, not a form to fill in.
class _PracticeActionCard extends StatelessWidget {
  const _PracticeActionCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: AppConstants.spacingLg,
            offset: const Offset(0, AppConstants.spacingSm),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: AppConstants.iconSizeLg,
                  height: AppConstants.iconSizeLg,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusDefault,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.mic_none,
                    color: AppColors.onPrimary,
                    size: AppConstants.iconSizeSm,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                // Expanded: a long translated title (e.g. Spanish "Iniciar
                // una práctica") must wrap or truncate here instead of
                // overflowing past the card on a narrow screen.
                Expanded(
                  child: Text(
                    tr('Start a practice session', 'Iniciar una práctica'),
                    style: textTheme.titleLarge
                        ?.copyWith(color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              tr(
                'Target role (optional)',
                'Puesto objetivo (opcional)',
              ),
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            CustomInput(
              hintText: tr(
                'e.g. Frontend Developer, QA Tester',
                'ej. Desarrolladora Frontend, QA Tester',
              ),
              onChanged: (value) => interviewDesiredRole.value = value,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            // The white pill button from the same "Next up" card — inverted
            // against the solid primary background instead of a filled
            // button that would just blend into it.
            Material(
              color: AppColors.onPrimary,
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                onTap: () => context.go('/interviews/session'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: AppColors.primary),
                      const SizedBox(width: AppConstants.spacingXs),
                      Text(
                        tr('Start practice', 'Empezar práctica'),
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
