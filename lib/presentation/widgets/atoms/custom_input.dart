// Atomic Design (Atom): Generic, reusable text field. The decoration
// (background, borders, icon color) comes from the theme; here we only add the
// focus glow from DESIGN.md — 2px of primary at 20% opacity — because an
// InputBorder can't paint shadows.
//
// It has no TextEditingController: the value comes out through [onChanged] and
// whoever uses it holds on to it, usually a signal. A controller would need a
// State to dispose of it, and the widgets in this project are StatelessWidget.

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class CustomInput extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;

  /// Every keystroke. It's the atom's only output.
  final ValueChanged<String>? onChanged;

  /// Enter or the keyboard's "done". Lets you submit the form without a mouse.
  final ValueChanged<String>? onSubmitted;

  /// Validation message under the field. Already localized: the atom doesn't
  /// translate.
  final String? errorText;

  /// Toggles between hiding and showing the text. When it is not null the
  /// field gets a reveal button, and whoever passes it owns the visibility:
  /// this atom keeps no state of its own.
  ///
  /// It exists because typing a password blind is where sign-up goes wrong,
  /// and the resulting failure reads as "wrong credentials", which points at
  /// the wrong problem.
  final VoidCallback? onToggleObscure;

  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Hints for the browser's and the password manager's autofill.
  final Iterable<String>? autofillHints;

  const CustomInput({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.onToggleObscure,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    // Focus.of registers the inherited dependency and rebuilds the Builder
    // when focus enters or leaves: the glow reacts with no state of its own
    // and no setState.
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
                suffixIcon: onToggleObscure == null
                    ? null
                    : IconButton(
                        onPressed: enabled ? onToggleObscure : null,
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        // Both are read by screen readers and shown on hover;
                        // they name the action, not the current state.
                        tooltip: obscureText ? 'Show password' : 'Hide password',
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
