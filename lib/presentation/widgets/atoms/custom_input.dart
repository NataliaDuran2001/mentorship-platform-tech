// Atomic Design (Átomo): Campo de texto genérico y reutilizable. La
// decoración (fondo, bordes, color del ícono) viene del tema; acá solo se
// agrega el glow de foco de DESIGN.md — 2px del primary al 20% de opacidad —
// porque un InputBorder no puede pintar sombras.
//
// No tiene TextEditingController: el valor sale por [onChanged] y lo guarda
// quien lo usa, normalmente un signal. Un controller necesitaría un State que
// lo libere, y los widgets de este proyecto son StatelessWidget.

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class CustomInput extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;

  /// Cada pulsación. Es la única salida del átomo.
  final ValueChanged<String>? onChanged;

  /// Enter o «listo» del teclado. Sirve para enviar el formulario sin mouse.
  final ValueChanged<String>? onSubmitted;

  /// Mensaje de validación bajo el campo. Ya en español: el átomo no traduce.
  final String? errorText;

  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Pistas para el autocompletado del navegador y del gestor de contraseñas.
  final Iterable<String>? autofillHints;

  const CustomInput({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    // Focus.of registra la dependencia inherited y reconstruye el Builder al
    // entrar o salir el foco: el glow reacciona sin estado propio ni setState.
    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;

          return AnimatedContainer(
            duration: AppConstants.durationFast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        spreadRadius: AppConstants.borderWidthThick,
                      ),
                    ]
                  : const [],
            ),
            child: TextField(
              obscureText: obscureText,
              enabled: enabled,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
                errorText: errorText,
              ),
            ),
          );
        },
      ),
    );
  }
}
