// Atomic Design (Page): Main structure that wires organisms together and
// handles dependency injection and the global or view state.
//
// After a successful sign in this page does NOT navigate: it sets
// `currentSession`, and the router's route guards decide where to go depending
// on whether onboarding is complete. A `context.go()` here would race the
// guard and could send the user to the wrong place.

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
    // Reactive region over signals. SignalBuilder replaces Watch, which
    // signals_flutter 7.1 deprecated; the decision is written down in §9 of
    // the E1 handoff and in CLAUDE.md.
    return SignalBuilder(
      builder: (context) {
        if (authLoading.value) {
          return const AuthLayout(
            title: 'Welcome',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // The resend is offered only if the account exists and is missing the
        // email link. For any other error it would make no sense.
        final needsConfirmation =
            authErrorKind.value == AuthFailureKind.emailNotConfirmed;

        return AuthLayout(
          title: 'Welcome',
          child: LoginForm(
            errorMessage: authError.value,
            onEmailChanged: (v) => loginEmail.value = v,
            onPasswordChanged: (v) => loginPassword.value = v,
            obscurePassword: !loginPasswordVisible.value,
            onToggleObscurePassword: () =>
                loginPasswordVisible.value = !loginPasswordVisible.value,
            onSubmit: signInWithEmail,
            onResendConfirmation: needsConfirmation
                ? () => resendConfirmationEmail(email: loginEmail.value.trim())
                : null,
            onGoToSignUp: () {
              clearAuthForms();
              context.go('/sign-up');
            },
            onForgotPassword: () {
              clearAuthForms();
              context.go('/forgot-password');
            },
          ),
        );
      },
    );
  }
}
