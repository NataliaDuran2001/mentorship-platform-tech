// Atomic Design (Atom): Irreducible component.
//
// A row of `totalSteps` dots connected by lines, showing which ones are
// done, which one is current, and which are still upcoming. Built for the
// interview-practice session, which needed a more visible progress signal
// than the thin AppProgressBar line: with only 5 steps, a "1 of 5" line is
// too subtle to tell where you stand at a glance.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class StepDotsIndicator extends StatelessWidget {
  const StepDotsIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// 1-based index of the step in progress. A value equal to [totalSteps] + 1
  /// (i.e. past the last step) reads every dot as done.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      child: Row(
        children: [
          for (var step = 1; step <= totalSteps; step++) ...[
            _Dot(state: _stateFor(step)),
            if (step != totalSteps)
              Expanded(
                child: Container(
                  height: AppConstants.borderWidthThick,
                  color: step < currentStep
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }

  _DotState _stateFor(int step) {
    if (step < currentStep) return _DotState.done;
    if (step == currentStep) return _DotState.current;
    return _DotState.upcoming;
  }
}

enum _DotState { done, current, upcoming }

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final _DotState state;

  @override
  Widget build(BuildContext context) {
    final size = state == _DotState.current
        ? AppConstants.stepDotSizeCurrent
        : AppConstants.stepDotSize;

    final Color background;
    final Color border;
    switch (state) {
      case _DotState.done:
        background = AppColors.primary;
        border = AppColors.primary;
      case _DotState.current:
        background = AppColors.primaryContainer;
        border = AppColors.primary;
      case _DotState.upcoming:
        background = AppColors.surfaceContainerHigh;
        border = AppColors.outlineVariant;
    }

    return AnimatedContainer(
      duration: AppConstants.durationFast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: border, width: AppConstants.borderWidthThick),
      ),
      child: state == _DotState.done
          ? const Icon(
              Icons.check,
              size: AppConstants.iconSizeSm,
              color: AppColors.onPrimary,
            )
          : null,
    );
  }
}
