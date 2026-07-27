// Atomic Design (Átomo): Componente irreductible.
// Recuadro de 48px con un ícono, el que acompaña a cada opción del onboarding.
//
// No detecta el hover por su cuenta: lo recibe en [isHighlighted]. En el
// prototipo el fondo del recuadro cambia cuando se pasa el mouse por la card
// entera (`group-hover`), no cuando se pasa por el recuadro. Quien conoce ese
// hover es la molécula que lo contiene.

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

  /// Resalta el recuadro: fondo `primaryContainer` en vez de `surfaceContainer`.
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
