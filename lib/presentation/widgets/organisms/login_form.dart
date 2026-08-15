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
import '../../utils/translate.dart';
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
                child: Text(
                  tr('Resend confirmation email', 'Reenviar correo de confirmación'),
                ),
              ),
            ),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
        CustomInput(
          hintText: tr('Email', 'Correo electrónico'),
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        CustomInput(
          hintText: tr('Password', 'Contraseña'),
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
            child: Text(tr('Forgot your password?', '¿Olvidaste tu contraseña?')),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding / 2),
        CustomButton(text: tr('Sign in', 'Iniciar sesión'), onPressed: onSubmit),
        const SizedBox(height: AppConstants.defaultPadding),
        // Wrap and not Row: on narrow screens the question and the link do not
        // fit in one line and a Row would overflow.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              tr("Don't have an account yet?", '¿Aún no tienes una cuenta?'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: onGoToSignUp,
              child: Text(tr('Sign up', 'Regístrate')),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Text(
                tr('OR', 'O'),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        GoogleLoginButton(
          disabledHint: tr(
            'Coming a bit later. For now, sign in with your email '
                'and password.',
            'Estará disponible un poco más adelante. Por ahora, inicia '
                'sesión con tu correo y contraseña.',
          ),
        ),
      ],
    );
  }
}
