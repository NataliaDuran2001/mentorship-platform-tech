// Atomic Design (Page): Main structure that wires organisms together and
// handles dependency injection and the global or view state.
//
// Before this issue there was no way to create an account: there was only
// login.
//
// The screen has two faces because email confirmation is on
// (`mailer_autoconfirm: false`): a successful sign up does NOT return a
// session, so after creating the account it shows "check your email" with the
// option to resend it. Going straight to the dashboard would be a lie.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../../utils/translate.dart';
import '../organisms/auth_layout.dart';
import '../organisms/sign_up_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (authLoading.value) {
          return AuthLayout(
            title: tr('Create your account', 'Crea tu cuenta'),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final pendingEmail = pendingConfirmationEmail.value;

        if (pendingEmail != null) {
          return AuthLayout(
            title: tr('Check your email', 'Revisa tu correo'),
            child: ConfirmationPending(
              email: pendingEmail,
              wasResent: confirmationEmailResent.value,
              errorMessage: authError.value,
              onResend: resendConfirmationEmail,
              onGoToLogin: () {
                pendingConfirmationEmail.value = null;
                clearAuthForms();
                context.go('/login');
              },
            ),
          );
        }

        return AuthLayout(
          title: tr('Create your account', 'Crea tu cuenta'),
          child: SignUpForm(
            errorMessage: authError.value,
            onNameChanged: (v) => signUpName.value = v,
            onEmailChanged: (v) => signUpEmail.value = v,
            onPasswordChanged: (v) => signUpPassword.value = v,
            obscurePassword: !signUpPasswordVisible.value,
            onToggleObscurePassword: () =>
                signUpPasswordVisible.value = !signUpPasswordVisible.value,
            onSubmit: signUpWithEmail,
            onGoToLogin: () {
              clearAuthForms();
              context.go('/login');
            },
          ),
        );
      },
    );
  }
}
