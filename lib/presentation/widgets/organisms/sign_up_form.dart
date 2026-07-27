// Atomic Design (Organism): Set of molecules and atoms that form a complete,
// self-contained functional section inside a page.
//
// Sign up form. It has two faces, and the second one exists because email
// confirmation is on (`mailer_autoconfirm: false`): a successful sign up does
// NOT return a session, so the screen has to say "check your email" and offer
// to resend it, instead of leaving the user waiting for something that is not
// going to happen.

import 'package:flutter/material.dart';

import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'auth_message.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onGoToLogin,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    this.errorMessage,
  });

  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;

  /// Whether the password travels hidden. The page owns it: this organism
  /// reads no signals.
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          AuthMessage(message: errorMessage!),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
        CustomInput(
          hintText: 'Your name (optional)',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: onNameChanged,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
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
          autofillHints: const [AutofillHints.newPassword],
          onChanged: onPasswordChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        CustomButton(text: 'Create account', onPressed: onSubmit),
        const SizedBox(height: AppConstants.defaultPadding),
        // Wrap and not Row: on narrow screens the question and the link do not
        // fit in one line and a Row would overflow.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: onGoToLogin,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The second face of sign up: account created, email still to be confirmed.
class ConfirmationPending extends StatelessWidget {
  const ConfirmationPending({
    super.key,
    required this.email,
    required this.onResend,
    required this.onGoToLogin,
    this.wasResent = false,
    this.errorMessage,
  });

  final String email;
  final VoidCallback onResend;
  final VoidCallback onGoToLogin;

  /// The resend went through. Without this feedback, tapping "resend" does not
  /// feel like anything happened.
  final bool wasResent;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthMessage(
          tone: AuthMessageTone.info,
          message: 'We sent an email to $email. Open the link inside to '
              'confirm your account, then sign in.',
        ),
        if (wasResent) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Email resent.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          AuthMessage(message: errorMessage!),
        ],
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        CustomButton(text: 'Go to sign in', onPressed: onGoToLogin),
        const SizedBox(height: AppConstants.spacingSm),
        TextButton(
          onPressed: onResend,
          child: const Text("It didn't arrive, resend the email"),
        ),
      ],
    );
  }
}
