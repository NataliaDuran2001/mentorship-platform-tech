// Atomic Design (Page): Main structure that wires organisms together and
// handles dependency injection and the global or view state.
//
// Where the password recovery email lands (issue #57). The link opens a
// session while this page loads (supabase_flutter consumes the token from the
// URL), so by the time the user submits, updating the password is a normal
// authenticated call. If the link expired or was reused, that call fails with
// `sessionExpired` and the page offers to request a fresh link.
//
// The route guard never redirects away from here (see app_router): bouncing
// to the path mid-recovery would leave the user signed in with the password
// they forgot.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/failures/auth_failure.dart';
import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../organisms/auth_layout.dart';
import '../organisms/auth_message.dart';

class PasswordRecoveryPage extends StatelessWidget {
  const PasswordRecoveryPage({super.key});

  void _submit() {
    final newPassword = passwordFormNew.value;
    final confirm = passwordFormConfirm.value;

    // Client-side checks mirror the sign-up rules; the backend re-validates.
    if (newPassword.length < 6) {
      passwordUpdateError.value =
          'That password is too weak. Use at least 6 characters.';
      return;
    }
    if (newPassword != confirm) {
      passwordUpdateError.value = "The passwords don't match. Check them "
          'and try again.';
      return;
    }
    submitRecoveredPassword(newPassword);
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (passwordUpdateDone.value) {
          return AuthLayout(
            title: 'Password updated',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthMessage(
                  tone: AuthMessageTone.info,
                  message: 'Your new password is set and you are signed in.',
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                CustomButton(
                  text: 'Go to my path',
                  onPressed: () {
                    resetPasswordFlows();
                    context.go('/path');
                  },
                ),
              ],
            ),
          );
        }

        // The expired link deserves its own way out, not just its message:
        // the fix is requesting a new one, and the button should say so.
        // Decided by kind, never by message text (same rule as authErrorKind).
        final expired =
            passwordUpdateErrorKind.value == AuthFailureKind.sessionExpired;

        return AuthLayout(
          title: 'Set a new password',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (passwordUpdateError.value != null) ...[
                AuthMessage(message: passwordUpdateError.value!),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
              if (expired)
                CustomButton(
                  text: 'Request a new link',
                  onPressed: () {
                    resetPasswordFlows();
                    context.go('/forgot-password');
                  },
                )
              else ...[
                Text(
                  'Choose the password you will sign in with from now on.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                CustomInput(
                  hintText: 'New password',
                  prefixIcon: Icons.lock,
                  obscureText: !passwordFormVisible.value,
                  onToggleObscure: () =>
                      passwordFormVisible.value = !passwordFormVisible.value,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (v) => passwordFormNew.value = v,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                CustomInput(
                  hintText: 'Confirm new password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !passwordFormVisible.value,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (v) => passwordFormConfirm.value = v,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                if (passwordUpdateLoading.value)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomButton(text: 'Save new password', onPressed: _submit),
              ],
            ],
          ),
        );
      },
    );
  }
}
