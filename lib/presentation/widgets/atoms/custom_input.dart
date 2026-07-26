// Atomic Design (Átomo): Campo de texto genérico y reutilizable. La
// decoración (fondo, bordes, color del ícono) viene del tema; acá solo se
// agrega el glow de foco de DESIGN.md — 2px del primary al 20% de opacidad —
// porque un InputBorder no puede pintar sombras.

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class CustomInput extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;

  const CustomInput({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
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
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: TextField(
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
