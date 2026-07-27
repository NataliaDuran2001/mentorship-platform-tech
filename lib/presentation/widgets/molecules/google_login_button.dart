// Atomic Design (Molécula): Combinación de átomos (ícono y botón genérico)
// construidos para un propósito un poco más específico pero aún reutilizable.
//
// El MVP autentica con email/password: Google OAuth es el issue #15
// (`fase:post-mvp`). El botón NO se borra —la pantalla del prototipo es
// Google-first y volverá a serlo—, pero queda deshabilitado con `onPressed` en
// `null`. Deshabilitado y sin cablear es lo correcto; cablearlo a un stub que
// falla sería peor que no ofrecerlo.

import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../../utils/app_colors.dart';

class GoogleLoginButton extends StatelessWidget {
  /// `null` deja el botón visible pero deshabilitado, que es el estado del MVP.
  final VoidCallback? onPressed;

  /// Texto de ayuda que explica por qué está deshabilitado.
  final String? disabledHint;

  const GoogleLoginButton({super.key, this.onPressed, this.disabledHint});

  @override
  Widget build(BuildContext context) {
    final boton = CustomButton(
      text: 'Iniciar con Google',
      onPressed: onPressed,
      isPrimary: false,
      // Usando el color secundario según el diseño
      icon: const Icon(
        Icons.g_mobiledata,
        size: 28,
        color: AppColors.secondary,
      ),
    );

    if (onPressed != null || disabledHint == null) return boton;

    return Tooltip(message: disabledHint!, child: boton);
  }
}
