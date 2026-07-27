// Atomic Design (Page): Where the link in the confirmation email lands
// (issue #34).
//
// Before this page the link dropped the user at the app root with no context:
// the app showed the plain login and asked again for the credentials she had
// just typed, with nothing saying whether the confirmation had worked.
//
// The Supabase SDK does the exchange on its own during initialize() —
// `detectSessionInUri` is on by default— so by the time this page builds the
// session either exists or it does not. This page only reports the outcome
// and offers the way forward; it never dead-ends.
//
// It reads `Uri.base` and not GoRouterState because Supabase puts its
// parameters wherever it wants relative to the hash fragment, and the browser
// URL is the only place guaranteed to hold them.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/custom_button.dart';
import '../organisms/auth_layout.dart';

/// Error that Supabase reports back on the redirect, already turned into copy.
///
/// It is not an [AuthFailure]: it never went through the Data layer, it comes
/// in the URL. The most common one by far is an expired or already used link.
String? _linkErrorMessage() {
  final parameters = <String, String>{
    ...Uri.base.queryParameters,
    // On the implicit flow the error travels in the fragment, after the route.
    ...Uri.splitQueryString(Uri.base.fragment.split('?').skip(1).join('?')),
  };

  final code = parameters['error_code'] ?? parameters['error'];
  if (code == null || code.isEmpty) return null;

  if (code.contains('expired')) {
    return 'That confirmation link expired. Sign up again or ask for a new '
        'email from the sign-in screen.';
  }
  return 'We could not confirm your account with that link. It may have been '
      'used already. Try signing in.';
}

class AuthConfirmedPage extends StatelessWidget {
  const AuthConfirmedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final error = _linkErrorMessage();
        final hasSession = isAuthenticated.value;

        if (error != null) {
          return _Outcome(
            title: 'Something went wrong',
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            message: error,
            actionLabel: 'Go to sign in',
            onAction: () {
              clearAuthForms();
              context.go('/login');
            },
          );
        }

        return _Outcome(
          title: 'Email confirmed',
          icon: Icons.mark_email_read_outlined,
          iconColor: AppColors.primary,
          message: hasSession
              ? 'Your account is ready. Continue to pick your learning path.'
              : 'Your account is ready. Sign in and we pick up where you '
                  'left off.',
          actionLabel: hasSession ? 'Continue' : 'Sign in',
          onAction: () {
            if (hasSession) {
              // Going to the root lets the route guards decide between the
              // onboarding and the learning path. Choosing here would race
              // them.
              context.go('/');
            } else {
              clearAuthForms();
              context.go('/login');
            }
          },
        );
      },
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: AppConstants.iconSizeLg, color: iconColor),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          CustomButton(text: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
