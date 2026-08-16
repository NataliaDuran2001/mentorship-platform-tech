// Atomic Design (Atom): Irreducible component.
// A generic, reusable base button that doesn't know its context. The styles
// live in the theme (AppTheme): here we only pick the variant —
// ElevatedButton is the primary one and OutlinedButton the secondary one.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;

  /// `null` disables the button, like any Material button. It's how step 2 of
  /// the onboarding keeps you from moving on without having picked a track.
  final VoidCallback? onPressed;

  final bool isPrimary;
  final Widget? icon;

  /// The action this button started is still running: it shows a spinner in
  /// place of its icon and stops responding.
  ///
  /// The waiting belongs *in* the button because the alternative — a page-wide
  /// indicator replacing the form — leaves nothing to read, nothing to cancel
  /// and no way back if the request never returns.
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final leading = isLoading
        ? const SizedBox(
            width: AppConstants.iconSizeSm,
            height: AppConstants.iconSizeSm,
            child: CircularProgressIndicator(
              strokeWidth: AppConstants.borderWidthThick,
              color: AppColors.onSurfaceVariant,
            ),
          )
        : icon ?? const SizedBox.shrink();
    final label = Text(text);
    final effectiveOnPressed = isLoading ? null : onPressed;

    return isPrimary
        ? ElevatedButton.icon(
            onPressed: effectiveOnPressed,
            icon: leading,
            label: label,
          )
        : OutlinedButton.icon(
            onPressed: effectiveOnPressed,
            icon: leading,
            label: label,
          );
  }
}
