// Atomic Design (Molécula): Combinación de átomos (ícono y botón genérico) 
// construidos para un propósito un poco más específico pero aún reutilizable.

import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../../utils/app_colors.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleLoginButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: 'Iniciar con Google',
      onPressed: onPressed,
      isPrimary: false,
      // Usando el color secundario según el diseño
      icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.secondary),
    );
  }
}
