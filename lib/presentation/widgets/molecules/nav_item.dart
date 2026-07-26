// Atomic Design (Molécula): Ítem de navegación para sidebar y drawer. Aplica
// el spec de listas del design system: tinte violeta al 5% y texto primary
// (ambos vía listTileTheme) más la barra activa de 2px en el borde izquierdo,
// que no es tematizable y por eso vive acá.

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: selected
              ? const BorderSide(width: 2, color: AppColors.primary)
              : BorderSide.none,
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
