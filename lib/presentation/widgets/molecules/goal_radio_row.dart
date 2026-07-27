// Atomic Design (Molécula): Combina átomos para formar un bloque funcional.
// La fila de una meta del paso 3: círculo de selección + etiqueta, con toda la
// fila clickeable y no solo el círculo.

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
            // Misma decoración que las cards. El prototipo solo cambia el borde
            // en hover y deja la selección al punto del círculo; acá la fila
            // seleccionada también se resalta, porque un punto de 12px es poca
            // señal para el estado elegido y el resto del flujo ya marca la
            // selección así. Anotado en la §9 del handoff.
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
