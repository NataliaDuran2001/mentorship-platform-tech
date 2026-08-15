// Presentation layer (Utils): Translation of authentication failures into
// messages for the user.
//
// It is the only place where an AuthFailureKind turns into visible text. The
// Data layer already translated the raw Supabase exception into a domain case;
// here it gets words. No widget builds these messages by hand.

import '../../domain/failures/auth_failure.dart';
import 'translate.dart';

/// Message for the user. It never includes the backend's technical detail.
String authFailureMessage(AuthFailure failure) {
  switch (failure.kind) {
    case AuthFailureKind.invalidCredentials:
      return tr(
        "That email or password isn't right.",
        'Ese correo o esa contraseña no son correctos.',
      );
    case AuthFailureKind.emailNotConfirmed:
      return tr(
        "Your account isn't confirmed yet. Check your email and "
            'follow the link we sent you.',
        'Tu cuenta todavía no está confirmada. Revisa tu correo y sigue '
            'el enlace que te enviamos.',
      );
    case AuthFailureKind.emailAlreadyRegistered:
      return tr(
        "There's already an account with that email. Try signing in.",
        'Ya existe una cuenta con ese correo. Intenta iniciar sesión.',
      );
    case AuthFailureKind.weakPassword:
      return tr(
        'That password is too weak. Use at least 6 characters.',
        'Esa contraseña es muy débil. Usa al menos 6 caracteres.',
      );
    case AuthFailureKind.samePassword:
      return tr(
        'Your new password must be different from the current one.',
        'Tu nueva contraseña debe ser diferente de la actual.',
      );
    case AuthFailureKind.sessionExpired:
      return tr(
        'That link is no longer valid. Request a new one and try again.',
        'Ese enlace ya no es válido. Solicita uno nuevo e inténtalo de '
            'nuevo.',
      );
    case AuthFailureKind.invalidEmail:
      return tr(
        "That email doesn't look valid. Check it and try again.",
        'Ese correo no parece válido. Revísalo e inténtalo de nuevo.',
      );
    case AuthFailureKind.tooManyRequests:
      return tr(
        'Too many tries in a row. Wait a few minutes and give it '
            'another go.',
        'Demasiados intentos seguidos. Espera unos minutos y vuelve a '
            'intentarlo.',
      );
    case AuthFailureKind.network:
      return tr(
        "We couldn't connect. Check your connection and try again.",
        'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
      );
    case AuthFailureKind.notImplemented:
      return tr(
        "That way of signing in isn't available yet.",
        'Esa forma de iniciar sesión todavía no está disponible.',
      );
    case AuthFailureKind.unknown:
      return tr(
        'Something went wrong. Try again in a moment.',
        'Algo salió mal. Inténtalo de nuevo en un momento.',
      );
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
