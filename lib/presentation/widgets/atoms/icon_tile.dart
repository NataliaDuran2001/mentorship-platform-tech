// Atomic Design (Atom): Irreducible component.
// 48px box with an icon, the one that goes with each onboarding option.
//
// It doesn't detect hover on its own: it gets it in [isHighlighted]. In the
// prototype the box background changes when you hover the whole card
// (`group-hover`), not when you hover the box. The one that knows about that
// hover is the molecule containing it.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.isHighlighted = false,
  });

  final IconData icon;

  /// Highlights the box: `primaryContainer` background instead of
  /// `surfaceContainer`.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.durationFast,
      width: AppConstants.iconTileSize,
      height: AppConstants.iconTileSize,
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryContainer
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}
