// Atomic Design (Átomo): Componente irreductible.
// Barra de progreso del onboarding. No sabe cuántos pasos hay ni en cuál está:
// recibe una fracción ya calculada, porque el total de pasos es variable —4 en
// la rama directa, 5 si se entra al cuestionario guía— y esa cuenta es
// responsabilidad de la página.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.semanticsLabel,
  });

  /// Fracción de avance, de 0 a 1. Se recorta al rango: un valor fuera de
  /// rango es un error de cálculo de la página, no algo que deba romper la UI.
  final double value;

  /// Texto para lectores de pantalla, ej. «Paso 2 de 5».
  final String? semanticsLabel;

  /// Curva del prototipo (`transition: width 0.6s cubic-bezier(0.65,0,0.35,1)`).
  static const Curve _curva = Cubic(0.65, 0, 0.35, 1);

  @override
  Widget build(BuildContext context) {
    final fraccion = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticsLabel,
      value: '${(fraccion * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        child: SizedBox(
          height: AppConstants.progressBarHeight,
          child: ColoredBox(
            color: AppColors.surfaceContainer,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fraccion),
              duration: AppConstants.durationSlow,
              curve: _curva,
              builder: (context, animado, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animado,
                  child: const ColoredBox(color: AppColors.primary),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
