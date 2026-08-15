// Atomic Design (Molecule): Combines atoms into a functional block.
// The onboarding action bar: Back · Skip · Continue.
//
// Each button's visibility comes in by parameter. The rule for when to show
// them does NOT live here: that "Skip" is forbidden on step 2 —without a track
// there's no roadmap, AC 1.3— belongs to issue #11, which is the one that
// knows the step.
//
// A hidden "Back" keeps its space (the prototype's `invisible`, not a
// `display:none`): that way "Continue" doesn't shift around between steps.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/custom_button.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.onContinue,
    this.onBack,
    this.onSkip,
    this.showBack = true,
    this.showSkip = true,
    this.continueLabel,
  });

  /// `null` disables the button: it's how step 2 keeps you from moving on
  /// without choosing.
  final VoidCallback? onContinue;

  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  final bool showBack;
  final bool showSkip;

  /// The last step says "Go to Dashboard" instead of "Continue".
  /// `null` falls back to the translated "Continue" label.
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final backButton = Visibility(
      visible: showBack,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: _GhostButton(
        label: tr('Back', 'Atrás'),
        onPressed: showBack ? onBack : null,
      ),
    );

    final skipButton = showSkip
        ? _GhostButton(label: tr('Skip', 'Omitir'), onPressed: onSkip)
        : const SizedBox.shrink();

    final continueButton = CustomButton(
      text: continueLabel ?? tr('Continue', 'Continuar'),
      onPressed: onContinue,
      isPrimary: true,
    );

    // On mobile the three buttons don't fit in one row —"Go to Dashboard" is
    // long—, so the main action takes up the full width on top and the
    // secondary ones sit underneath. We measure the footer's width and not the
    // window's, because the footer lives inside a panel with margins.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppConstants.footerCompactWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              continueButton,
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [backButton, skipButton],
              ),
            ],
          );
        }

        return Row(
          children: [
            backButton,
            const Spacer(),
            if (showSkip)
              Padding(
                padding: const EdgeInsets.only(right: AppConstants.spacingSm),
                child: skipButton,
              ),
            continueButton,
          ],
        );
      },
    );
  }
}

/// The prototype's ghost button: no background, no border, dimmed text.
///
/// It doesn't use CustomButton because its secondary variant is an
/// OutlinedButton, which does have a border. The theme's `textButtonTheme` is
/// the design system's ghost variant, but it paints the text in `primary`; in
/// the onboarding footer the two secondary actions go in `onSurfaceVariant` so
/// they don't compete with "Continue". Extracting a ghost variant out of
/// CustomButton is noted down for when #9 touches the login buttons.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }
}
