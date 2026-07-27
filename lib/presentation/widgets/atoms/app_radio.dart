// Atomic Design (Átomo): Componente irreductible.
// El círculo de selección de las metas del paso 3. Solo pinta: no responde al
// tap ni sabe a qué grupo pertenece.
//
// No usa el Radio de Material porque este design system lo especifica distinto
// (24px, borde de 2px, punto interior de 12px que aparece con fade) y porque el
// Radio de Material exige un `groupValue` que acoplaría el átomo al conjunto.
// La fila completa clickeable la arma GoalRadioRow.

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
          // El punto no se monta y desmonta: siempre está y cambia de opacidad,
          // que es lo que da el fade del prototipo (`transition-opacity`).
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
