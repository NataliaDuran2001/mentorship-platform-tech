// Atomic Design (Átomo): Componente irreductible.
// El contador «PASO 1 DE 4». Recibe los dos números; no los deduce.
//
// El total es un parámetro y no una constante porque el onboarding tiene 4
// pasos por la rama directa y 5 si se entra al cuestionario guía. De ahí venía
// la discrepancia entre los dos mockups.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class StepCounterLabel extends StatelessWidget {
  const StepCounterLabel({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Paso actual, empezando en 1.
  final int currentStep;

  final int totalSteps;

  /// `tracking-widest` del prototipo: 0.1em sobre los 12px de labelMedium.
  static const double _tracking = 1.2;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Paso $currentStep de $totalSteps'.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: _tracking,
          ),
    );
  }
}
