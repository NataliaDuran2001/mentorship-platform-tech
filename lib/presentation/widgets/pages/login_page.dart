// Atomic Design (Página): Estructura principal que une organismos y maneja
// la inyección de dependencias y el estado global o de la vista.
//
// Después de un ingreso exitoso esta página NO navega: cambia `currentSession`,
// y los route guards del router deciden a dónde ir según si el onboarding está
// completo. Un `context.go()` acá competiría con el guard y podría mandar a la
// usuaria al lugar equivocado.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/failures/auth_failure.dart';
import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../organisms/auth_layout.dart';
import '../organisms/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Región reactiva sobre signals. SignalBuilder reemplaza a Watch, que
    // signals_flutter 7.1 deprecó; la decisión está anotada en la §9 del
    // handoff de E1 y en CLAUDE.md.
    return SignalBuilder(
      builder: (context) {
        if (authLoading.value) {
          return const AuthLayout(
            title: 'Bienvenida',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // El reenvío se ofrece solo si la cuenta existe y le falta el enlace
        // del correo. En cualquier otro error no tendría sentido.
        final faltaConfirmar =
            authErrorKind.value == AuthFailureKind.emailNotConfirmed;

        return AuthLayout(
          title: 'Bienvenida',
          child: LoginForm(
            errorMessage: authError.value,
            onEmailChanged: (v) => loginEmail.value = v,
            onPasswordChanged: (v) => loginPassword.value = v,
            onSubmit: signInWithEmail,
            onResendConfirmation: faltaConfirmar
                ? () => resendConfirmationEmail(email: loginEmail.value.trim())
                : null,
            onGoToSignUp: () {
              limpiarFormulariosDeAuth();
              context.go('/registro');
            },
          ),
        );
      },
    );
  }
}
