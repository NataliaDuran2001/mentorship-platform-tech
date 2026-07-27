// Presentation layer (State): Authentication state with signals.
//
// This file only declares signals; the one that fills them is
// auth_actions.dart. The separation is on purpose: this way the state can be
// read and reset from a test without dragging in getIt or Supabase.
//
// `isAuthenticated` is a `computed` derived from the real session, not a
// boolean the UI sets to `true` by hand like in the original scaffold: that was
// debt 3 of §3 of the handoff. Now it is impossible for the app to believe it
// is authenticated without having a session.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_failure.dart';

/// Current session, or `null` if there is none. It is written by the bootstrap
/// and by the repository's session change stream.
final currentSession = signal<AuthSession?>(null);

/// Profile of the authenticated user. `null` without a session or if it has
/// not been read yet.
final currentProfile = signal<UserProfile?>(null);

/// There is a session. Derived, not writable.
final isAuthenticated = computed(() => currentSession.value != null);

/// The onboarding is finished. It requires a track on top of the timestamp, so
/// no path leads to the dashboard with a null `track_id`.
final hasCompletedOnboarding =
    computed(() => currentProfile.value?.hasCompletedOnboarding ?? false);

/// An authentication operation is in progress.
final authLoading = signal<bool>(false);

/// Error message, already translated. `null` if there is no error.
final authError = signal<String?>(null);

/// Kind of the last failure, for the UI decisions that depend on *which* error
/// it was and not on its text. Today the only one: offering to resend the email
/// only when the account exists and still needs confirming.
final authErrorKind = signal<AuthFailureKind?>(null);

/// Email left waiting for confirmation after a successful sign-up.
///
/// With `mailer_autoconfirm: false` the sign-up returns no session, so this is
/// the "check your email" state: the sign-up screen shows it and offers to
/// resend the email.
final pendingConfirmationEmail = signal<String?>(null);

/// Confirmation that the email was resent, to give visible feedback.
final confirmationEmailResent = signal<bool>(false);

// ---------------------------------------------------------------------------
// Form fields
//
// They live in signals and not in a TextEditingController because the widgets
// of the project are StatelessWidget: a controller would need a State to
// dispose of it. The trade-off is that the password stays in global memory, so
// it is cleared as soon as it is used (see clearAuthForms).
// ---------------------------------------------------------------------------

final loginEmail = signal<String>('');
final loginPassword = signal<String>('');
final signUpName = signal<String>('');
final signUpEmail = signal<String>('');
final signUpPassword = signal<String>('');

/// Whether the password fields are showing their text (issue #33).
///
/// They start hidden and go back to hidden whenever the forms are cleared: a
/// revealed password left on screen after leaving the page would be worse
/// than the typo it helps to avoid.
final loginPasswordVisible = signal<bool>(false);
final signUpPasswordVisible = signal<bool>(false);

/// Empties the fields and the messages. It is called when entering and leaving
/// the authentication screens, and after every successful submit.
void clearAuthForms() {
  loginEmail.value = '';
  loginPassword.value = '';
  signUpName.value = '';
  signUpEmail.value = '';
  signUpPassword.value = '';
  loginPasswordVisible.value = false;
  signUpPasswordVisible.value = false;
  authError.value = null;
  authErrorKind.value = null;
  confirmationEmailResent.value = false;
}
