// Atomic Design (Molecule): Combination of atoms (icon and generic button)
// built for a slightly more specific purpose but still reusable.
//
// The MVP authenticates with email/password: Google OAuth is issue #15
// (`fase:post-mvp`). The button is NOT deleted —the prototype screen is
// Google-first and will be again—, but it stays disabled with `onPressed` set
// to `null`. Disabled and unwired is the right call; wiring it to a stub that
// fails would be worse than not offering it.

import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../../utils/app_colors.dart';

class GoogleLoginButton extends StatelessWidget {
  /// `null` leaves the button visible but disabled, which is the MVP state.
  final VoidCallback? onPressed;

  /// Helper text explaining why it's disabled.
  final String? disabledHint;

  const GoogleLoginButton({super.key, this.onPressed, this.disabledHint});

  @override
  Widget build(BuildContext context) {
    final button = CustomButton(
      text: 'Continue with Google',
      onPressed: onPressed,
      isPrimary: false,
      // Using the secondary color as per the design
      icon: const Icon(
        Icons.g_mobiledata,
        size: 28,
        color: AppColors.secondary,
      ),
    );

    if (onPressed != null || disabledHint == null) return button;

    return Tooltip(message: disabledHint!, child: button);
  }
}
