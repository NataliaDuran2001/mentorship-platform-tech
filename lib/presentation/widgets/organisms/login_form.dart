// Atomic Design (Organismo): Conjunto de moléculas y átomos que forman
// una sección funcional completa e independiente dentro de una página.
//
// Formulario de ingreso con correo y contraseña. No lee signals ni resuelve
// dependencias: recibe los callbacks y el mensaje de error ya traducido. Quien
// conecta con getIt es LoginPage.
//
// El botón de Google sigue en la pantalla pero deshabilitado: el MVP autentica
// con email/password y Google es el issue #15.

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
    this.errorMessage,
    this.onResendConfirmation,
  });

  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoToSignUp;

  /// Ya en español. `null` si no hay error.
  final String? errorMessage;

  /// Se ofrece solo cuando el fallo fue «cuenta sin confirmar»: la usuaria
  /// existe y su contraseña era correcta, solo le falta el enlace del correo.
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
                child: const Text('Reenviar el correo de confirmación'),
              ),
            ),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
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
          autofillHints: const [AutofillHints.password],
          onChanged: onPasswordChanged,
          // Enter envía: en web se espera poder entrar sin tocar el botón.
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        CustomButton(text: 'Ingresar', onPressed: onSubmit),
        const SizedBox(height: AppConstants.defaultPadding),
        // Wrap y no Row: en pantallas angostas la pregunta y el enlace no
        // caben en una línea y un Row desbordaría.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿Todavía no tenés cuenta?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: onGoToSignUp,
              child: const Text('Registrate'),
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
                'O',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        const GoogleLoginButton(
          disabledHint: 'Disponible más adelante. Por ahora ingresá con tu '
              'correo y contraseña.',
        ),
      ],
    );
  }
}
