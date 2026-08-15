// Atomic Design (Page): Main structure that wires organisms together and
// handles dependency injection and the global or view state.
//
// Where the password recovery email lands (issue #57). The link carries a
// `token_hash` that this page exchanges for a session on mount (verifyOtp).
// It is deliberately NOT the PKCE code exchange: PKCE only works on the exact
// browser profile that requested the email, and recovery emails are routinely
// opened somewhere else — another profile, another device. The token hash
// works anywhere, which is the whole point of the flow.
//
// It requires the Reset Password email template to link to
// `{{ .RedirectTo }}?token_hash={{ .TokenHash }}&type=recovery` (see the PR).
//
// The route guard never redirects away from here (see app_router): bouncing
// to the path mid-recovery would leave the user signed in with the password
// they forgot.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/failures/auth_failure.dart';
import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../organisms/auth_layout.dart';
import '../organisms/auth_message.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key, this.tokenHash});

  /// The `token_hash` query parameter of the emailed link. `null` when the
  /// page is reached without one — then there is nothing to exchange and the
  /// submit surfaces the missing session as an expired link.
  final String? tokenHash;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  @override
  void initState() {
    super.initState();
    // The exchange runs on arrival, not on submit: an expired link should
    // say so before anyone types a new password twice.
    final token = widget.tokenHash;
    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => verifyRecoveryToken(token));
    }
  }

  void _submit() {
    final newPassword = passwordFormNew.value;
    final confirm = passwordFormConfirm.value;

    // Client-side checks mirror the sign-up rules; the backend re-validates.
    if (newPassword.length < 6) {
      passwordUpdateError.value = tr(
        'That password is too weak. Use at least 6 characters.',
        'Esa contraseña es muy débil. Usa al menos 6 caracteres.',
      );
      return;
    }
    if (newPassword != confirm) {
      passwordUpdateError.value = tr(
        "The passwords don't match. Check them "
            'and try again.',
        'Las contraseñas no coinciden. Revísalas e inténtalo de nuevo.',
      );
      return;
    }
    submitRecoveredPassword(newPassword);
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (passwordUpdateDone.value) {
          return AuthLayout(
            title: tr('Password updated', 'Contraseña actualizada'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthMessage(
                  tone: AuthMessageTone.info,
                  message: tr(
                    'Your new password is set and you are signed in.',
                    'Tu nueva contraseña quedó configurada y ya iniciaste '
                        'sesión.',
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                CustomButton(
                  text: tr('Go to my path', 'Ir a mi ruta'),
                  onPressed: () {
                    resetPasswordFlows();
                    context.go('/path');
                  },
                ),
              ],
            ),
          );
        }

        // The expired link deserves its own way out, not just its message:
        // the fix is requesting a new one, and the button should say so.
        // Decided by kind, never by message text (same rule as authErrorKind).
        final expired =
            passwordUpdateErrorKind.value == AuthFailureKind.sessionExpired;

        return AuthLayout(
          title: tr('Set a new password', 'Crea una nueva contraseña'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (passwordUpdateError.value != null) ...[
                AuthMessage(message: passwordUpdateError.value!),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
              if (expired)
                CustomButton(
                  text: tr('Request a new link', 'Solicitar un enlace nuevo'),
                  onPressed: () {
                    resetPasswordFlows();
                    context.go('/forgot-password');
                  },
                )
              else ...[
                Text(
                  tr(
                    'Choose the password you will sign in with from now on.',
                    'Elige la contraseña con la que iniciarás sesión de '
                        'ahora en adelante.',
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                CustomInput(
                  hintText: tr('New password', 'Nueva contraseña'),
                  prefixIcon: Icons.lock,
                  obscureText: !passwordFormVisible.value,
                  onToggleObscure: () =>
                      passwordFormVisible.value = !passwordFormVisible.value,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (v) => passwordFormNew.value = v,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                CustomInput(
                  hintText: tr('Confirm new password', 'Confirma la nueva contraseña'),
                  prefixIcon: Icons.lock_outline,
                  obscureText: !passwordFormVisible.value,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (v) => passwordFormConfirm.value = v,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                if (passwordUpdateLoading.value)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomButton(
                    text: tr('Save new password', 'Guardar nueva contraseña'),
                    onPressed: _submit,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
