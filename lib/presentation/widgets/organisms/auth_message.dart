// Atomic Design (Organism): Reusable functional section.
// Error or notice banner for the authentication screens.
//
// It takes text that is already user-facing. It never takes an exception: the
// Data layer turns the Supabase exception into an AuthFailure and
// utils/auth_error_messages.dart turns that into text. That way no raw backend
// error can reach the screen, not even by accident.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

enum AuthMessageTone { error, info }

class AuthMessage extends StatelessWidget {
  const AuthMessage({
    super.key,
    required this.message,
    this.tone = AuthMessageTone.error,
  });

  final String message;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == AuthMessageTone.error;
    final background =
        isError ? AppColors.errorContainer : AppColors.primaryFixed;
    final foreground =
        isError ? AppColors.onErrorContainer : AppColors.onPrimaryFixed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.mark_email_unread_outlined,
            color: foreground,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
