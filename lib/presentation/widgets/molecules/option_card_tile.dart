// Atomic Design (Molecule): Combines atoms into a functional block.
// The onboarding's horizontal option: icon box + title + description.
// It's the step 1 row (experience level).
//
// It doesn't know which step it's on, or whether the step allows skipping, or
// which option is the right one: it takes [isSelected] and reports back
// through [onTap]. That's what lets issues #11 and #12 reuse it without
// duplicating it.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/selectable_card_style.dart';
import '../atoms/hover_builder.dart';
import '../atoms/icon_tile.dart';

class OptionCardTile extends StatelessWidget {
  const OptionCardTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String title;

  /// Second line, optional: step 2 shows only the title.
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
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Row(
                    children: [
                      IconTile(
                        icon: icon,
                        isHighlighted: isSelected || isHovered,
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            if (description != null) ...[
                              const SizedBox(height: AppConstants.spacingXs),
                              Text(
                                description!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
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
