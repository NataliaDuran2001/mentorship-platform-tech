// Atomic Design (Organism): Set of molecules and atoms that form a complete,
// self-contained functional section inside a page.
//
// Sign in form with email and password. It does not read signals nor resolve
// dependencies: it takes the callbacks and the already user-facing error
// message. LoginPage is the one that wires it to getIt.
//
// The Google button is still on the screen but disabled: the MVP authenticates
// with email/password and Google is issue #15.

import 'package:flutter/material.dart';

import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../molecules/google_login_button.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'auth_message.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onGoToSignUp,
    required this.onForgotPassword,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    this.errorMessage,
    this.onResendConfirmation,
  });

  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoToSignUp;

  /// Opens the password recovery flow (issue #57).
  final VoidCallback onForgotPassword;

  /// Whether the password travels hidden. The page owns it: this organism
  /// reads no signals.
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;

  /// Already user-facing text. `null` when there is no error.
  final String? errorMessage;

  /// Offered only when the failure was "unconfirmed account": the user exists
  /// and her password was right, she is only missing the link in the email.
  final VoidCallback? onResendConfirmation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          AuthMessage(message: errorMessage!),
          if (onResendConfirmation != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onResendConfirmation,
                child: const Text('Resend confirmation email'),
              ),
            ),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
        CustomInput(
          hintText: 'Email',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        CustomInput(
          hintText: 'Password',
          prefixIcon: Icons.lock,
          obscureText: obscurePassword,
          onToggleObscure: onToggleObscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: onPasswordChanged,
          // Enter submits: on web you expect to get in without the button.
          onSubmitted: (_) => onSubmit(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            child: const Text('Forgot your password?'),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding / 2),
        CustomButton(text: 'Sign in', onPressed: onSubmit),
        const SizedBox(height: AppConstants.defaultPadding),
        // Wrap and not Row: on narrow screens the question and the link do not
        // fit in one line and a Row would overflow.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Don't have an account yet?",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: onGoToSignUp,
              child: const Text('Sign up'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Text(
                'OR',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        const GoogleLoginButton(
          disabledHint: 'Coming a bit later. For now, sign in with your email '
              'and password.',
        ),
      ],
    );
  }
}
