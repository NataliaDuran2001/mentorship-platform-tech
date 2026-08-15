// Atomic Design (Organism): Reusable functional section.
// The shared frame of every onboarding step: progress bar, counter, title,
// subtitle, content and action footer, plus the decorative desktop column.
//
// It is not in the organism list of issue #11, and it exists because the
// alternative was having the four steps —five with the guided quiz of #12—
// repeat the same header and footer. Every copy is a chance for one step to
// look different.
//
// It does not read state: it takes the step number, the total and the
// visibility flags. OnboardingPage is the one that computes them.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/app_progress_bar.dart';
import '../atoms/step_counter_label.dart';
import '../molecules/onboarding_footer.dart';

class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.onSkip,
    this.onContinue,
    this.showBack = true,
    this.showSkip = true,
    this.continueLabel,
    this.errorMessage,
  });

  final int currentStep;
  final int totalSteps;

  /// Step heading. `null` or empty when the content brings its own, like the
  /// summary with its confirmation icon.
  final String? title;

  final String? subtitle;
  final Widget child;

  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;
  final bool showBack;
  final bool showSkip;

  /// `null` falls back to the default label inside [OnboardingFooter].
  final String? continueLabel;

  /// Already user-facing text.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width > AppConstants.breakpointTablet;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppProgressBar(
          value: currentStep / totalSteps,
          semanticsLabel: tr(
            'Step $currentStep of $totalSteps',
            'Paso $currentStep de $totalSteps',
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        StepCounterLabel(currentStep: currentStep, totalSteps: totalSteps),
        const SizedBox(height: AppConstants.spacingLg),
        if (title != null && title!.isNotEmpty)
          Text(title!, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        child,
        if (errorMessage != null) ...[
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            errorMessage!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppConstants.spacingXl),
        OnboardingFooter(
          onBack: onBack,
          onSkip: onSkip,
          onContinue: onContinue,
          showBack: showBack,
          showSkip: showSkip,
          continueLabel: continueLabel,
        ),
      ],
    );

    final panel = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: AppConstants.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2/5 of the width for the decorative column, like the
                // prototype.
                const Expanded(flex: 2, child: _DecorativePanel()),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingXl),
                    child: SingleChildScrollView(child: content),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: SingleChildScrollView(child: content),
            ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.containerMax,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Left desktop column.
///
/// The prototype puts an illustration here; the repository does not have that
/// asset yet, so it is solved with the design system tokens instead of
/// referencing a file that does not exist. Replaceable without touching
/// anything else.
class _DecorativePanel extends StatelessWidget {
  const _DecorativePanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.explore_outlined,
              color: AppColors.onPrimary,
              size: AppConstants.iconTileSize,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              tr('Your future starts here', 'Tu futuro empieza aquí'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              tr(
                "We're with you at every step of your tech career, with clarity "
                    'and empathy.',
                'Estamos contigo en cada paso de tu carrera en tech, con '
                    'claridad y empatía.',
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
