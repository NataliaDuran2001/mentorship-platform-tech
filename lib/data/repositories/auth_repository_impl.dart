// Capa Data: Implementación concreta de los repositorios definidos en Domain.
// Aquí se hacen las peticiones al backend (Supabase).
//
// ESTADO: andamio. El issue #8 amplió el contrato `AuthRepository`; la
// implementación real contra `SupabaseClient` es del issue #9. Hasta entonces
// cada método lanza `UnimplementedError` en vez de simular éxito: un stub que
// devuelve datos falsos se cuela hasta producción, uno que explota no.
//
// Esta clase todavía no está registrada en `getIt` (ver core/di/injection.dart),
// así que nada la invoca.

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  static Never _pendiente(String metodo) =>
      throw UnimplementedError('AuthRepositoryImpl.$metodo: issue #9');

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async =>
      _pendiente('signUp');

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _pendiente('signInWithEmail');

  /// Google queda fuera del MVP por decisión de producto. No es un pendiente
  /// del #9: se habilita en el issue #15 (`fase:post-mvp`), que así resulta
  /// puramente aditivo sobre esta clase.
  @override
  Future<AuthResult> signInWithGoogle() async => throw UnimplementedError(
        'Inicio de sesión con Google: issue #15 (post-MVP)',
      );

  @override
  Future<void> signOut() async => _pendiente('signOut');

  @override
  Future<void> resendConfirmationEmail({required String email}) async =>
      _pendiente('resendConfirmationEmail');

  @override
  AuthSession? get currentSession => _pendiente('currentSession');

  @override
  Stream<AuthSession?> get sessionChanges => _pendiente('sessionChanges');
}
