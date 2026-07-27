// Atomic Design (Atom): Irreducible component.
// Onboarding progress bar. It doesn't know how many steps there are or which
// one it's on: it takes an already-computed fraction, because the total number
// of steps varies —4 on the direct path, 5 if you enter the guided
// questionnaire— and that count is the page's responsibility.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.semanticsLabel,
  });

  /// Progress fraction, from 0 to 1. It gets clamped to the range: a value out
  /// of range is a math error in the page, not something that should break the
  /// UI.
  final double value;

  /// Text for screen readers, e.g. "Step 2 of 5".
  final String? semanticsLabel;

  /// Prototype curve (`transition: width 0.6s cubic-bezier(0.65,0,0.35,1)`).
  static const Curve _curve = Cubic(0.65, 0, 0.35, 1);

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticsLabel,
      value: '${(fraction * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        child: SizedBox(
          height: AppConstants.progressBarHeight,
          child: ColoredBox(
            color: AppColors.surfaceContainer,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fraction),
              duration: AppConstants.durationSlow,
              curve: _curve,
              builder: (context, animated, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animated,
                  child: const ColoredBox(color: AppColors.primary),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
