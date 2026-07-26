// Atomic Design (Átomo): Componente irreductible. 
// Es un botón base genérico y reutilizable que no conoce su contexto.

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : AppColors.neutral,
        foregroundColor: isPrimary ? Colors.white : AppColors.secondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: isPrimary ? BorderSide.none : const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      onPressed: onPressed,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(
        text, 
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
