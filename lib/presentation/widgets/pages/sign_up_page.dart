// Atomic Design (Página): Estructura principal que une organismos y maneja
// la inyección de dependencias y el estado global o de la vista.
//
// Antes de este issue no existía forma de crear una cuenta: solo había login.
//
// La pantalla tiene dos caras porque la confirmación por correo está activa
// (`mailer_autoconfirm: false`): un registro exitoso NO devuelve sesión, así que
// después de crear la cuenta se muestra «revisá tu correo» con la opción de
// reenviarlo. Navegar directo al dashboard sería mentir.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../organisms/auth_layout.dart';
import '../organisms/sign_up_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (authLoading.value) {
          return const AuthLayout(
            title: 'Creá tu cuenta',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final pendiente = pendingConfirmationEmail.value;

        if (pendiente != null) {
          return AuthLayout(
            title: 'Revisá tu correo',
            child: ConfirmationPending(
              email: pendiente,
              wasResent: confirmationEmailResent.value,
              errorMessage: authError.value,
              onResend: resendConfirmationEmail,
              onGoToLogin: () {
                pendingConfirmationEmail.value = null;
                limpiarFormulariosDeAuth();
                context.go('/login');
              },
            ),
          );
        }

        return AuthLayout(
          title: 'Creá tu cuenta',
          child: SignUpForm(
            errorMessage: authError.value,
            onNameChanged: (v) => signUpName.value = v,
            onEmailChanged: (v) => signUpEmail.value = v,
            onPasswordChanged: (v) => signUpPassword.value = v,
            onSubmit: signUpWithEmail,
            onGoToLogin: () {
              limpiarFormulariosDeAuth();
              context.go('/login');
            },
          ),
        );
      },
    );
  }
}
