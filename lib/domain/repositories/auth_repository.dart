// Capa Domain: Contrato (interfaz) del repositorio de autenticación.
// Define QUÉ se puede hacer, no CÓMO. La implementación vive en `data`.
//
// Todos los métodos que fallan lanzan `AuthFailure` (nunca la excepción cruda
// del backend). La implementación real es del issue #9.

import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Registra una cuenta nueva con correo y contraseña.
  ///
  /// Con la confirmación por correo activa el resultado trae `session` en
  /// `null` y `requiresEmailConfirmation` en `true`. Eso es éxito, no fallo.
  ///
  /// Lanza `AuthFailure` con `emailAlreadyRegistered`, `weakPassword` o
  /// `invalidEmail` según corresponda.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Inicia sesión con correo y contraseña.
  ///
  /// Lanza `AuthFailure` con `invalidCredentials` si no coinciden y con
  /// `emailNotConfirmed` si la cuenta existe pero no está confirmada.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Inicia sesión con Google.
  ///
  /// Reservado para el issue #15 (`fase:post-mvp`). El MVP es email/password,
  /// así que la implementación lanza `UnimplementedError`. Está en el contrato
  /// desde ahora para que el #15 sea puramente aditivo.
  Future<AuthResult> signInWithGoogle();

  /// Cierra la sesión actual. Idempotente: sin sesión no hace nada.
  Future<void> signOut();

  /// Reenvía el correo de confirmación de una cuenta sin confirmar.
  Future<void> resendConfirmationEmail({required String email});

  /// Sesión vigente, o `null` si no hay. Lectura sincrónica: el SDK restaura
  /// la sesión persistida antes de que arranque la UI.
  AuthSession? get currentSession;

  /// Cambios de sesión: login, logout, refresco de token y confirmación de
  /// correo. Emite `null` cuando la sesión se cierra.
  Stream<AuthSession?> get sessionChanges;
}
