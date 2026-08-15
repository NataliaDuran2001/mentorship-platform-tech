// Presentation layer (Utils): Translation of authentication failures into
// messages for the user.
//
// It is the only place where an AuthFailureKind turns into visible text. The
// Data layer already translated the raw Supabase exception into a domain case;
// here it gets words. No widget builds these messages by hand.

import '../../domain/failures/auth_failure.dart';

/// Message for the user. It never includes the backend's technical detail.
String authFailureMessage(AuthFailure failure) {
  switch (failure.kind) {
    case AuthFailureKind.invalidCredentials:
      return "That email or password isn't right.";
    case AuthFailureKind.emailNotConfirmed:
      return "Your account isn't confirmed yet. Check your email and "
          'follow the link we sent you.';
    case AuthFailureKind.emailAlreadyRegistered:
      return "There's already an account with that email. Try signing in.";
    case AuthFailureKind.weakPassword:
      return 'That password is too weak. Use at least 6 characters.';
    case AuthFailureKind.samePassword:
      return 'Your new password must be different from the current one.';
    case AuthFailureKind.sessionExpired:
      return 'That link is no longer valid. Request a new one and try again.';
    case AuthFailureKind.invalidEmail:
      return "That email doesn't look valid. Check it and try again.";
    case AuthFailureKind.tooManyRequests:
      return 'Too many tries in a row. Wait a few minutes and give it '
          'another go.';
    case AuthFailureKind.network:
      return "We couldn't connect. Check your connection and try again.";
    case AuthFailureKind.notImplemented:
      return "That way of signing in isn't available yet.";
    case AuthFailureKind.unknown:
      return 'Something went wrong. Try again in a moment.';
  }
}

/// Message for any error, translated or not.
///
/// It exists because a `catch` in the UI can receive something that is not an
/// AuthFailure —a bug of ours, for instance— and not even then can the raw
/// text be shown.
String errorMessage(Object error) {
  if (error is AuthFailure) return authFailureMessage(error);
  return authFailureMessage(const AuthFailure(AuthFailureKind.unknown));
}
