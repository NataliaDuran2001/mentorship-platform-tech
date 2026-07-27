// Atomic Design (Atom): Irreducible component.
// A generic, reusable base button that doesn't know its context. The styles
// live in the theme (AppTheme): here we only pick the variant —
// ElevatedButton is the primary one and OutlinedButton the secondary one.

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;

  /// `null` disables the button, like any Material button. It's how step 2 of
  /// the onboarding keeps you from moving on without having picked a track.
  final VoidCallback? onPressed;

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
