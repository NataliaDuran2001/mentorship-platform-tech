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

// ---------------------------------------------------------------------------
// Password recovery and change (issue #57)
// ---------------------------------------------------------------------------

/// The recovery email was requested and (as far as the user may know) sent.
///
/// It is also true when the account does not exist: enumeration protection
/// means the UI says "if that email has an account..." either way.
final recoveryEmailSent = signal<bool>(false);

/// A password update (recovery landing or profile form) is in progress.
final passwordUpdateLoading = signal<bool>(false);

/// Error of the last password update, already translated. `null` if none.
final passwordUpdateError = signal<String?>(null);

/// Kind of the last password update failure, for the decisions that depend on
/// *which* error it was: today, offering a fresh link when the recovery link
/// expired. Mirrors [authErrorKind].
final passwordUpdateErrorKind = signal<AuthFailureKind?>(null);

/// The last password update finished successfully.
final passwordUpdateDone = signal<bool>(false);

/// Fields of the recovery/change forms. Shared: the recovery landing and the
/// profile form never coexist on screen, and both are cleared together.
final passwordFormEmail = signal<String>('');
final passwordFormCurrent = signal<String>('');
final passwordFormNew = signal<String>('');
final passwordFormConfirm = signal<String>('');
final passwordFormVisible = signal<bool>(false);

/// Leaves the recovery/change state as freshly opened. Called when entering
/// the screens that use it, so nobody meets the previous attempt's outcome —
/// or its passwords.
void resetPasswordFlows() {
  recoveryEmailSent.value = false;
  passwordUpdateLoading.value = false;
  passwordUpdateError.value = null;
  passwordUpdateErrorKind.value = null;
  passwordUpdateDone.value = false;
  passwordFormEmail.value = '';
  passwordFormCurrent.value = '';
  passwordFormNew.value = '';
  passwordFormConfirm.value = '';
  passwordFormVisible.value = false;
}

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
  // Without this, "check your email" outlived the sign-up that produced it:
  // going to the login and back to "Create your account" showed the previous
  // attempt's confirmation screen instead of an empty form, because the
  // sign-up page decides which face to show from this signal alone.
  pendingConfirmationEmail.value = null;
  resetPasswordFlows();
}
