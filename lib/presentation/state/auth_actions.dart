// Presentation layer (State): Authentication actions.
//
// It is the only place in the Presentation layer that touches getIt. Widgets
// call these functions; they do not resolve use cases nor build repositories.
//
// It is kept apart from auth_state.dart for two reasons: the signals file stays
// dependency-free and testable on its own, and the session logic —bootstrap,
// change stream, logout— needs a home that is not a page, because more than one
// screen uses it.

import 'dart:async';

import '../../core/di/injection.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../utils/auth_error_messages.dart';
import 'ai_state.dart';
import 'auth_state.dart';
import 'interview_state.dart';
import 'onboarding_actions.dart';
import 'onboarding_state.dart';
import 'roadmap_state.dart';

StreamSubscription<AuthSession?>? _sessionSubscription;

/// Leaves the authentication state ready before the UI is mounted.
///
/// It reads the session the SDK already restored from storage —which is why
/// reloading the page does not kick anyone out— and, if there is one, fetches
/// the profile. It happens here and not inside the route guards so that the
/// guard never has to decide with the profile half loaded: when the app starts,
/// either there is a session and a profile, or there is no session.
Future<void> bootstrapAuth() async {
  final repository = getIt<AuthRepository>();

  currentSession.value = repository.currentSession;
  if (currentSession.value != null) {
    await refreshProfile();
  }

  _sessionSubscription?.cancel();
  _sessionSubscription = repository.sessionChanges.listen((session) async {
    final hadSession = currentSession.value != null;
    currentSession.value = session;

    if (session == null) {
      currentProfile.value = null;
      return;
    }
    // On sign-in it fetches the profile; on a token refresh it already has it.
    if (!hadSession || currentProfile.value == null) {
      await refreshProfile();
    }
  });
}

/// Reads the authenticated user's profile again.
///
/// It is called after signing in and every time the onboarding changes the
/// profile, so the route guards decide with fresh data.
Future<void> refreshProfile() async {
  try {
    final profile = await getIt<OnboardingRepository>().loadProfile();
    currentProfile.value = profile;

    // Half-finished onboarding: the partial state is rebuilt before the screen
    // is mounted, so we land on the first unanswered step instead of the
    // previous one already marked (issue #14). Here and not in the page because
    // the route guard decides where to go before any widget exists.
    if (profile != null && !profile.hasCompletedOnboarding) {
      await restoreOnboarding();
    }
  } catch (e) {
    // It is not translated into authError: the profile is read in the
    // background and a failure here must not paint an error on the login
    // screen. The guard will see a null profile and send the user to the
    // onboarding, which retries it.
    currentProfile.value = null;
  }
}

/// Signs in with email and password.
///
/// Returns `true` if a session was opened. It leaves the error message, already
/// translated, in [authError].
Future<bool> signInWithEmail() async {
  final email = loginEmail.value.trim();
  final password = loginPassword.value;

  if (email.isEmpty || password.isEmpty) {
    authError.value = 'Fill in your email and your password.';
    return false;
  }

  authLoading.value = true;
  _clearError();

  try {
    final result = await getIt<SignInUseCase>()(
      email: email,
      password: password,
    );
    currentSession.value = result.session;
    if (result.session != null) await refreshProfile();

    // The password does not stay in memory longer than needed.
    loginPassword.value = '';
    return result.isSignedIn;
  } catch (e) {
    _recordError(e);
    return false;
  } finally {
    authLoading.value = false;
  }
}

/// Registers a new account.
///
/// With email confirmation on, the normal case is that there is NO session: the
/// email is left in [pendingConfirmationEmail] and the screen shows "check your
/// email". Returns `true` if the sign-up went well, with or without a session.
Future<bool> signUpWithEmail() async {
  final email = signUpEmail.value.trim();
  final password = signUpPassword.value;
  final name = signUpName.value.trim();

  if (email.isEmpty || password.isEmpty) {
    authError.value = 'Fill in your email and your password.';
    return false;
  }

  authLoading.value = true;
  _clearError();

  try {
    final result = await getIt<SignUpUseCase>()(
      email: email,
      password: password,
      displayName: name.isEmpty ? null : name,
    );

    if (result.requiresEmailConfirmation) {
      pendingConfirmationEmail.value = email;
    } else {
      currentSession.value = result.session;
      await refreshProfile();
    }

    signUpPassword.value = '';
    return true;
  } catch (e) {
    _recordError(e);
    return false;
  } finally {
    authLoading.value = false;
  }
}

/// Resends the confirmation email to the given [email], or to the one left
/// pending by the last sign-up.
Future<void> resendConfirmationEmail({String? email}) async {
  final target = email ?? pendingConfirmationEmail.value;
  if (target == null || target.isEmpty) return;

  authLoading.value = true;
  _clearError();
  confirmationEmailResent.value = false;

  try {
    await getIt<AuthRepository>().resendConfirmationEmail(email: target);
    confirmationEmailResent.value = true;
  } catch (e) {
    _recordError(e);
  } finally {
    authLoading.value = false;
  }
}

/// Requests the password recovery email (issue #57).
///
/// Success here only means "the request was accepted": with enumeration
/// protection on, the backend answers the same whether the account exists or
/// not, and the UI phrases it accordingly.
Future<void> requestPasswordRecovery(String email) async {
  final target = email.trim();
  if (target.isEmpty) return;

  passwordUpdateLoading.value = true;
  passwordUpdateError.value = null;
  recoveryEmailSent.value = false;

  try {
    await getIt<AuthRepository>().requestPasswordRecovery(email: target);
    recoveryEmailSent.value = true;
  } catch (e) {
    passwordUpdateError.value = errorMessage(e);
  } finally {
    passwordUpdateLoading.value = false;
  }
}

/// Sets the new password from the recovery landing (issue #57).
///
/// The emailed link already opened a session by the time this runs; if it did
/// not (expired or reused link), the repository surfaces `sessionExpired` and
/// the page offers to request a new link.
Future<void> submitRecoveredPassword(String newPassword) async {
  passwordUpdateLoading.value = true;
  passwordUpdateError.value = null;
  passwordUpdateErrorKind.value = null;

  try {
    await getIt<AuthRepository>().updatePassword(newPassword: newPassword);
    passwordUpdateDone.value = true;
  } catch (e) {
    passwordUpdateError.value = errorMessage(e);
    passwordUpdateErrorKind.value = e is AuthFailure ? e.kind : null;
  } finally {
    passwordUpdateLoading.value = false;
  }
}

/// Changes the password of the signed-in user from the profile (issue #57).
///
/// The current password is verified first by signing in again: Supabase's
/// update does not ask for it, but silently accepting a change from an open
/// session on a shared computer would hand the account to whoever sits down
/// next.
Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  final email = currentSession.value?.email;
  if (email == null || email.isEmpty) return;

  passwordUpdateLoading.value = true;
  passwordUpdateError.value = null;
  passwordUpdateDone.value = false;

  try {
    await getIt<SignInUseCase>()(email: email, password: currentPassword);
    await getIt<AuthRepository>().updatePassword(newPassword: newPassword);
    passwordUpdateDone.value = true;
  } on AuthFailure catch (e) {
    // The re-sign-in failing with bad credentials means the *current*
    // password box is wrong; the generic message would blame the email too.
    passwordUpdateError.value = e.kind == AuthFailureKind.invalidCredentials
        ? "That current password isn't right."
        : errorMessage(e);
  } catch (e) {
    passwordUpdateError.value = errorMessage(e);
  } finally {
    passwordUpdateLoading.value = false;
  }
}

/// Signs out and clears all derived state.
Future<void> signOut() async {
  authLoading.value = true;
  try {
    await getIt<SignOutUseCase>()();
  } catch (e) {
    _recordError(e);
  } finally {
    // It is cleared even if the backend failed: leaving the app "with a
    // session" after the user asked to leave is worse than a local-only logout.
    currentSession.value = null;
    currentProfile.value = null;
    pendingConfirmationEmail.value = null;
    clearAuthForms();
    // The onboarding of the user who leaves cannot stay loaded for the one who
    // comes in next.
    cancelOnboardingTimers();
    resetOnboarding();
    resetRoadmap();
    resetInterviewState();
    // The summary and the coaching lines are written about the person who is
    // leaving; without this they greeted the next one by their progress.
    resetAiState();
    authLoading.value = false;
  }
}

/// Stores the translated message and the kind of the failure.
///
/// The UI needs the kind to decide *what* to offer, not *what to say*: today,
/// showing the email resend only when the account exists and still needs
/// confirming.
void _clearError() {
  authError.value = null;
  authErrorKind.value = null;
}

void _recordError(Object e) {
  authError.value = errorMessage(e);
  authErrorKind.value = e is AuthFailure ? e.kind : AuthFailureKind.unknown;
}

/// Stops listening to the session stream. For the tests.
Future<void> disposeAuthListener() async {
  await _sessionSubscription?.cancel();
  _sessionSubscription = null;
}
