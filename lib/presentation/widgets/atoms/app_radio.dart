// Atomic Design (Atom): Irreducible component.
// The selection circle for the step 3 goals. It only paints: it doesn't react
// to taps and doesn't know which group it belongs to.
//
// It doesn't use Material's Radio because this design system specs it
// differently (24px, 2px border, 12px inner dot that fades in) and because
// Material's Radio requires a `groupValue` that would couple the atom to the
// group. GoalRadioRow builds the full clickable row.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class AppRadio extends StatelessWidget {
  const AppRadio({super.key, required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppConstants.radioSize,
      height: AppConstants.radioSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.outline,
            width: AppConstants.borderWidthThick,
          ),
        ),
        child: Center(
          // The dot isn't mounted and unmounted: it's always there and changes
          // opacity, which is what gives the prototype's fade
          // (`transition-opacity`).
          child: AnimatedOpacity(
            duration: AppConstants.durationFast,
            opacity: isSelected ? 1 : 0,
            child: Container(
              width: AppConstants.radioDotSize,
              height: AppConstants.radioDotSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
