// Atomic Design (Organismo): Conjunto de moléculas y átomos que forman
// una sección funcional completa e independiente dentro de una página.
//
// Formulario de registro. Tiene dos caras, y la segunda existe porque la
// confirmación por correo está activa (`mailer_autoconfirm: false`): un registro
// exitoso NO devuelve sesión, así que la pantalla tiene que decir «revisá tu
// correo» y ofrecer reenviarlo, en vez de dejar a la usuaria esperando algo que
// no va a pasar.

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
    this.errorMessage,
  });

  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;
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
          hintText: 'Tu nombre (opcional)',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: onNameChanged,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        CustomInput(
          hintText: 'Correo electrónico',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        CustomInput(
          hintText: 'Contraseña',
          prefixIcon: Icons.lock,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: onPasswordChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        CustomButton(text: 'Crear cuenta', onPressed: onSubmit),
        const SizedBox(height: AppConstants.defaultPadding),
        // Wrap y no Row: en pantallas angostas la pregunta y el enlace no
        // caben en una línea y un Row desbordaría.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿Ya tenés cuenta?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: onGoToLogin,
              child: const Text('Ingresá'),
            ),
          ],
        ),
      ],
    );
  }
}

/// La segunda cara del registro: cuenta creada, falta confirmar el correo.
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

  /// El reenvío salió bien. Sin este feedback, tocar «reenviar» no se siente.
  final bool wasResent;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthMessage(
          tone: AuthMessageTone.info,
          message: 'Te enviamos un correo a $email. Abrí el enlace que está '
              'adentro para confirmar tu cuenta y después ingresá.',
        ),
        if (wasResent) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Correo reenviado.',
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
        CustomButton(text: 'Ir a ingresar', onPressed: onGoToLogin),
        const SizedBox(height: AppConstants.spacingSm),
        TextButton(
          onPressed: onResend,
          child: const Text('No me llegó, reenviar el correo'),
        ),
      ],
    );
  }
}
