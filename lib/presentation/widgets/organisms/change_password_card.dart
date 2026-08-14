// Atomic Design (Organism): Reusable functional section.
//
// The profile's change-password form (issue #57). It asks for the current
// password even though the backend does not: silently accepting a change from
// an open session on a shared computer would hand the account to whoever sits
// down next.
//
// Like the other auth organisms it reads no signals and resolves nothing: it
// takes values, callbacks and already user-facing messages; ProfilePage wires
// it to the state.

import 'package:flutter/material.dart';

import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'auth_message.dart';

class ChangePasswordCard extends StatelessWidget {
  const ChangePasswordCard({
    super.key,
    required this.onCurrentChanged,
    required this.onNewChanged,
    required this.onConfirmChanged,
    required this.onSubmit,
    required this.obscurePasswords,
    required this.onToggleObscure,
    required this.isLoading,
    required this.isDone,
    this.errorMessage,
  });

  final ValueChanged<String> onCurrentChanged;
  final ValueChanged<String> onNewChanged;
  final ValueChanged<String> onConfirmChanged;
  final VoidCallback onSubmit;
  final bool obscurePasswords;
  final VoidCallback onToggleObscure;
  final bool isLoading;

  /// The last change went through; the card shows the confirmation instead of
  /// leaving the filled form on screen as if nothing had happened.
  final bool isDone;

  /// Already user-facing text. `null` when there is no error.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change password',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            if (isDone)
              const AuthMessage(
                tone: AuthMessageTone.info,
                message: 'Your password was updated.',
              )
            else ...[
              if (errorMessage != null) ...[
                AuthMessage(message: errorMessage!),
                const SizedBox(height: AppConstants.spacingMd),
              ],
              CustomInput(
                hintText: 'Current password',
                prefixIcon: Icons.lock_outline,
                obscureText: obscurePasswords,
                onToggleObscure: onToggleObscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                onChanged: onCurrentChanged,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              CustomInput(
                hintText: 'New password',
                prefixIcon: Icons.lock,
                obscureText: obscurePasswords,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: onNewChanged,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              CustomInput(
                hintText: 'Confirm new password',
                prefixIcon: Icons.lock,
                obscureText: obscurePasswords,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: onConfirmChanged,
                onSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                CustomButton(text: 'Update password', onPressed: onSubmit),
            ],
          ],
        ),
      ),
    );
  }
}
