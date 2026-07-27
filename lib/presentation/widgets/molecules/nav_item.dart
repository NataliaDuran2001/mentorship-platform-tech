// Atomic Design (Molecule): Navigation item for sidebar and drawer. Applies
// the design system's list spec: violet tint at 5% and primary text (both via
// listTileTheme) plus the 2px active bar on the left edge, which isn't
// themeable and that's why it lives here.

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
