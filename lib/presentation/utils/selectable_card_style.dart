// Capa Presentation (Utils): Decoración compartida de las tarjetas
// seleccionables del onboarding.
//
// Vive acá y no duplicada en cada molécula porque los tres controles del flujo
// —OptionCardTile, TrackCard y GoalRadioRow— comparten exactamente los mismos
// estados, y si se desincronizan la pantalla se ve inconsistente entre pasos.
//
// Valores del prototipo `descubre_tu_ruta_onboarding/code.html`:
//
//   .option-card:hover   { border-color: #674bb5; background: rgba(103,75,181,.05) }
//   .option-card.selected{ border-color: #674bb5; background: rgba(103,75,181,.08);
//                          box-shadow: 0 0 0 1px #674bb5 }
//
// `#674bb5` es AppColors.primary; acá se usa el token, no el hex.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'constants.dart';

/// Opacidad del fondo violeta en hover y en seleccionado.
const double _alphaHover = 0.05;
const double _alphaSelected = 0.08;

/// Decoración de una tarjeta seleccionable.
///
/// [isSelected] gana sobre [isHovered]: pasar el mouse por una opción ya
/// elegida no la atenúa.
BoxDecoration selectableCardDecoration({
  required bool isSelected,
  required bool isHovered,
}) {
  final resaltada = isSelected || isHovered;

  return BoxDecoration(
    color: isSelected
        ? AppColors.primary.withValues(alpha: _alphaSelected)
        : isHovered
            ? AppColors.primary.withValues(alpha: _alphaHover)
            : Colors.transparent,
    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
    border: Border.all(
      color: resaltada ? AppColors.primary : AppColors.outlineVariant,
      width: AppConstants.borderWidth,
    ),
    // El `box-shadow: 0 0 0 1px` del prototipo: un anillo sin difuminado que
    // engrosa el borde al seleccionar, sin mover el layout como haría subir el
    // ancho del borde a 2px.
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
