// Atomic Design (Atom): Irreducible component.
// The "STEP 1 OF 4" counter. It takes both numbers; it doesn't infer them.
//
// The total is a parameter and not a constant because the onboarding has 4
// steps on the direct path and 5 if you enter the guided questionnaire. That's
// where the discrepancy between the two mockups came from.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class StepCounterLabel extends StatelessWidget {
  const StepCounterLabel({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Current step, starting at 1.
  final int currentStep;

  final int totalSteps;

  /// The prototype's `tracking-widest`: 0.1em over labelMedium's 12px.
  static const double _tracking = 1.2;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Step $currentStep of $totalSteps'.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: _tracking,
          ),
    );
  }
}
