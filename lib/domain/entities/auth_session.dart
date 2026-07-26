// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Sesión de autenticación en términos del dominio. Existe para que ni
// `presentation` ni `domain` tengan que conocer el tipo `Session` de
// supabase_flutter: la capa Data traduce uno al otro.

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    this.emailConfirmedAt,
  });

  final String userId;
  final String email;

  /// Cuándo se confirmó el correo, o `null` si sigue sin confirmar.
  final DateTime? emailConfirmedAt;

  bool get isEmailConfirmed => emailConfirmedAt != null;
}

/// Resultado de un registro o un inicio de sesión.
///
/// La confirmación por correo está activa (`mailer_autoconfirm: false`), así
/// que un registro exitoso devuelve [session] en `null` y
/// [requiresEmailConfirmation] en `true`. No es un error: es el estado
/// «revisá tu correo» que la UI tiene que mostrar.
class AuthResult {
  const AuthResult({
    this.session,
    this.requiresEmailConfirmation = false,
  });

  final AuthSession? session;
  final bool requiresEmailConfirmation;

  /// Hay sesión utilizable.
  bool get isSignedIn => session != null;
}
