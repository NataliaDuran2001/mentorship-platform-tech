// Capa Domain: Vocabulario de fallos de los contratos (Dart puro).
//
// Existe para cumplir la regla «ningún error crudo de Supabase a la vista»
// (issue #9) sin que `presentation` importe supabase_flutter: la capa Data
// traduce cada `AuthException` del SDK a uno de estos casos, y la capa
// Presentation los mapea a mensajes en español.

/// Casos de fallo de autenticación que la UI necesita distinguir.
enum AuthFailureKind {
  /// Correo o contraseña incorrectos.
  invalidCredentials,

  /// Las credenciales son válidas pero el correo sigue sin confirmar.
  /// La UI ofrece reenviar el correo de confirmación.
  emailNotConfirmed,

  /// Ya existe una cuenta con ese correo.
  emailAlreadyRegistered,

  /// La contraseña no cumple la política mínima de Supabase.
  weakPassword,

  /// El correo no tiene formato válido.
  invalidEmail,

  /// Demasiados intentos seguidos.
  tooManyRequests,

  /// No se pudo hablar con el backend.
  network,

  /// El proveedor todavía no está implementado (Google, issue #15).
  notImplemented,

  /// Cualquier otra cosa. La UI muestra un mensaje genérico.
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, {this.technicalDetail});

  final AuthFailureKind kind;

  /// Mensaje original del backend. Solo para diagnóstico y logs: nunca se
  /// muestra tal cual a la usuaria.
  final String? technicalDetail;

  @override
  String toString() => 'AuthFailure(${kind.name}): ${technicalDetail ?? '-'}';
}
