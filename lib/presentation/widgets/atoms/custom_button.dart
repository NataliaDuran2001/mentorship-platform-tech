// Atomic Design (Átomo): Componente irreductible.
// Es un botón base genérico y reutilizable que no conoce su contexto. Los
// estilos viven en el tema (AppTheme): acá solo se elige la variante —
// ElevatedButton es el primario y OutlinedButton el secundario.

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final leading = icon ?? const SizedBox.shrink();
    final label = Text(text);

    return isPrimary
        ? ElevatedButton.icon(onPressed: onPressed, icon: leading, label: label)
        : OutlinedButton.icon(onPressed: onPressed, icon: leading, label: label);
  }
}
