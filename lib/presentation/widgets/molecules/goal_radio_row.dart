// Atomic Design (Molecule): Combines atoms into a functional block.
// The row for a step 3 goal: selection circle + label, with the whole row
// clickable and not just the circle.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/selectable_card_style.dart';
import '../atoms/app_radio.dart';
import '../atoms/hover_builder.dart';

class GoalRadioRow extends StatelessWidget {
  const GoalRadioRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: label,
      child: HoverBuilder(
        builder: (context, isHovered) {
          return AnimatedContainer(
            duration: AppConstants.durationFast,
            // Same decoration as the cards. The prototype only changes the
            // border on hover and leaves the selection to the circle's dot;
            // here the selected row is highlighted too, because a 12px dot is
            // a weak signal for the chosen state and the rest of the flow
            // already marks selection this way. Noted in §9 of the handoff.
            decoration: selectableCardDecoration(
              isSelected: isSelected,
              isHovered: isHovered,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Row(
                    children: [
                      AppRadio(isSelected: isSelected),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
