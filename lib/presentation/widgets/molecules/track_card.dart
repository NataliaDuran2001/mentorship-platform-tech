// Atomic Design (Molecule): Combines atoms into a functional block.
// Vertical, centered variant of the option, for the step 2 track grid and for
// the guided questionnaire in issue #12.
//
// It's a separate molecule and not a parameter of OptionCardTile because the
// layout changes axis: a `Row` and a `Column` aren't the same composition with
// a different flag. They do share the visual states, via
// selectableCardDecoration.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/selectable_card_style.dart';
import '../atoms/hover_builder.dart';
import '../atoms/icon_tile.dart';

class TrackCard extends StatelessWidget {
  const TrackCard({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String title;

  /// The step 2 grid omits it; the guided questionnaire shows it.
  final String? description;

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: HoverBuilder(
        builder: (context, isHovered) {
          return AnimatedContainer(
            duration: AppConstants.durationFast,
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
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTile(
                        icon: icon,
                        isHighlighted: isSelected || isHovered,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        Text(
                          description!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
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
