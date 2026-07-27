// Atomic Design (Molécula): Combina átomos para formar un bloque funcional.
// La opción horizontal del onboarding: recuadro de ícono + título + descripción.
// Es la fila del paso 1 (nivel de experiencia).
//
// No sabe en qué paso está, ni si el paso permite omitir, ni qué opción es la
// correcta: recibe [isSelected] y avisa por [onTap]. Eso es lo que permite que
// los issues #11 y #12 la reutilicen sin duplicarla.

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

  /// Segunda línea, opcional: el paso 2 muestra solo el título.
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
