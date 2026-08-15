// Atomic Design (Page): Main structure that wires organisms together and
// handles dependency injection and the global or view state.
//
// Requests the password recovery email (issue #57). Public: whoever forgot
// their password has no session by definition. The success copy does not say
// whether the account exists — enumeration protection answers the same either
// way, and this page must not undo that on the screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../organisms/auth_layout.dart';
import '../organisms/auth_message.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (recoveryEmailSent.value) {
          return AuthLayout(
            title: tr('Check your email', 'Revisa tu correo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthMessage(
                  tone: AuthMessageTone.info,
                  message: tr(
                    'If that email has an account, the link to set a '
                        'new password is on its way. It may take a minute.',
                    'Si ese correo tiene una cuenta, el enlace para crear '
                        'una nueva contraseña ya va en camino. Puede tardar '
                        'un minuto.',
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                CustomButton(
                  text: tr('Back to sign in', 'Volver a iniciar sesión'),
                  onPressed: () {
                    clearAuthForms();
                    context.go('/login');
                  },
                ),
              ],
            ),
          );
        }

        return AuthLayout(
          title: tr('Reset your password', 'Restablece tu contraseña'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (passwordUpdateError.value != null) ...[
                AuthMessage(message: passwordUpdateError.value!),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
              Text(
                tr(
                  'Tell us the email of your account and we will send you a '
                  'link to set a new password.',
                  'Cuéntanos el correo de tu cuenta y te enviaremos un '
                  'enlace para crear una nueva contraseña.',
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              CustomInput(
                hintText: tr('Email', 'Correo electrónico'),
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onChanged: (v) => passwordFormEmail.value = v,
                onSubmitted: (_) =>
                    requestPasswordRecovery(passwordFormEmail.value),
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              if (passwordUpdateLoading.value)
                const Center(child: CircularProgressIndicator())
              else
                CustomButton(
                  text: tr('Send recovery link', 'Enviar enlace de recuperación'),
                  onPressed: () =>
                      requestPasswordRecovery(passwordFormEmail.value),
                ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextButton(
                onPressed: () {
                  clearAuthForms();
                  context.go('/login');
                },
                child: Text(tr('Back to sign in', 'Volver a iniciar sesión')),
              ),
            ],
          ),
        );
      },
    );
  }
}
