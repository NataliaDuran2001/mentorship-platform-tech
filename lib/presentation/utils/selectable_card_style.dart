// Presentation layer (Utils): Shared decoration of the selectable cards of the
// onboarding.
//
// It lives here and not duplicated in each molecule because the three controls
// of the flow —OptionCardTile, TrackCard and GoalRadioRow— share exactly the
// same states, and if they drift apart the screen looks inconsistent between
// steps.
//
// Values from the `descubre_tu_ruta_onboarding/code.html` prototype:
//
//   .option-card:hover   { border-color: #674bb5; background: rgba(103,75,181,.05) }
//   .option-card.selected{ border-color: #674bb5; background: rgba(103,75,181,.08);
//                          box-shadow: 0 0 0 1px #674bb5 }
//
// `#674bb5` is AppColors.primary; the token is used here, not the hex.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'constants.dart';

/// Opacity of the purple background on hover and when selected.
const double _alphaHover = 0.05;
const double _alphaSelected = 0.08;

/// Decoration of a selectable card.
///
/// [isSelected] wins over [isHovered]: hovering over an already chosen option
/// does not dim it.
BoxDecoration selectableCardDecoration({
  required bool isSelected,
  required bool isHovered,
}) {
  final highlighted = isSelected || isHovered;

  return BoxDecoration(
    color: isSelected
        ? AppColors.primary.withValues(alpha: _alphaSelected)
        : isHovered
            ? AppColors.primary.withValues(alpha: _alphaHover)
            : Colors.transparent,
    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
    border: Border.all(
      color: highlighted ? AppColors.primary : AppColors.outlineVariant,
      width: AppConstants.borderWidth,
    ),
    // The `box-shadow: 0 0 0 1px` from the prototype: a ring without blur that
    // thickens the border on selection, without shifting the layout the way
    // raising the border width to 2px would.
    boxShadow: isSelected
        ? const [
            BoxShadow(
              color: AppColors.primary,
              spreadRadius: AppConstants.borderWidth,
            ),
          ]
        : null,
  );
}
