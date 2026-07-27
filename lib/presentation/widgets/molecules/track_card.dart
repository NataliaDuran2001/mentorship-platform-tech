// Atomic Design (Molécula): Combina átomos para formar un bloque funcional.
// Variante vertical y centrada de la opción, para la grilla de tracks del paso
// 2 y para el cuestionario guía del issue #12.
//
// Es una molécula aparte y no un parámetro de OptionCardTile porque el layout
// cambia de eje: un `Row` y un `Column` no son la misma composición con otro
// flag. Los estados visuales sí los comparten, vía selectableCardDecoration.

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

  /// La grilla del paso 2 la omite; el cuestionario guía la muestra.
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
