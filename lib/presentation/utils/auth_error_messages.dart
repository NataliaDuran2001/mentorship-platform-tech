// Capa Presentation (Utils): Traducción de los fallos de autenticación a
// mensajes en español.
//
// Es el único lugar donde un AuthFailureKind se convierte en texto visible.
// La capa Data ya tradujo la excepción cruda de Supabase a un caso del
// dominio; acá se le pone palabras. Ningún widget arma estos mensajes a mano.

import '../../domain/failures/auth_failure.dart';

/// Mensaje para la usuaria. Nunca incluye el detalle técnico del backend.
String mensajeDeAuthFailure(AuthFailure fallo) {
  switch (fallo.kind) {
    case AuthFailureKind.invalidCredentials:
      return 'El correo o la contraseña no son correctos.';
    case AuthFailureKind.emailNotConfirmed:
      return 'Tu cuenta todavía no está confirmada. Revisá tu correo y '
          'seguí el enlace que te enviamos.';
    case AuthFailureKind.emailAlreadyRegistered:
      return 'Ya existe una cuenta con ese correo. Probá iniciar sesión.';
    case AuthFailureKind.weakPassword:
      return 'La contraseña es demasiado débil. Usá al menos 6 caracteres.';
    case AuthFailureKind.invalidEmail:
      return 'Ese correo no parece válido. Revisalo y probá de nuevo.';
    case AuthFailureKind.tooManyRequests:
      return 'Demasiados intentos seguidos. Esperá unos minutos y volvé a '
          'probar.';
    case AuthFailureKind.network:
      return 'No pudimos conectarnos. Revisá tu conexión e intentá otra vez.';
    case AuthFailureKind.notImplemented:
      return 'Esa forma de ingresar todavía no está disponible.';
    case AuthFailureKind.unknown:
      return 'Algo no funcionó. Intentá de nuevo en un momento.';
  }
}

/// Mensaje para cualquier error, traducido o no.
///
/// Existe porque un `catch` de la UI puede recibir algo que no sea
/// AuthFailure —un bug nuestro, por ejemplo— y ni siquiera en ese caso puede
/// mostrarse el texto crudo.
String mensajeDeError(Object error) {
  if (error is AuthFailure) return mensajeDeAuthFailure(error);
  return mensajeDeAuthFailure(const AuthFailure(AuthFailureKind.unknown));
}
