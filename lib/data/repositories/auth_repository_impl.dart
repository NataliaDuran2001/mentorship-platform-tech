// Capa Data: Implementación concreta del contrato AuthRepository contra
// Supabase Auth.
//
// Toma el SupabaseClient por constructor —lo inyecta getIt— y nunca llama a
// Supabase.instance.client.
//
// Su otra responsabilidad es traducir: ninguna excepción del SDK sale de esta
// clase. Todo lo que falla sale como AuthFailure, con un caso de
// AuthFailureKind que la capa Presentation convierte en un mensaje en español.
// Es lo que permite cumplir «ningún error crudo de Supabase a la vista» sin
// que presentation importe supabase_flutter.

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _traducir(() async {
      final respuesta = await _client.auth.signUp(
        email: email,
        password: password,
        // Lo lee el trigger handle_new_user() para llenar
        // profiles.display_name.
        data: displayName == null || displayName.isEmpty
            ? null
            : <String, dynamic>{'display_name': displayName},
      );

      // Con la protección contra enumeración de correos activada, registrar un
      // correo que ya existe NO devuelve error: devuelve un usuario con la
      // lista de identidades vacía. Sin este chequeo la UI diría «revisá tu
      // correo» a alguien que ya tiene cuenta y que nunca va a recibir nada.
      final identidades = respuesta.user?.identities;
      if (identidades != null && identidades.isEmpty) {
        throw const AuthFailure(AuthFailureKind.emailAlreadyRegistered);
      }

      // Con mailer_autoconfirm en false esto es lo normal: usuario creado, sin
      // sesión, esperando que confirme el correo. Es éxito, no fallo.
      return AuthResult(
        session: _aSesion(respuesta.session),
        requiresEmailConfirmation: respuesta.session == null,
      );
    });
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _traducir(() async {
      final respuesta = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResult(session: _aSesion(respuesta.session));
    });
  }

  /// Reservado para el issue #15 (`fase:post-mvp`).
  ///
  /// Lanza `UnimplementedError` a propósito, y no un `AuthFailure`: no es un
  /// fallo de ejecución que la UI deba mostrar, es código que todavía no
  /// existe. La pantalla de login deja el botón de Google deshabilitado, así
  /// que este camino no se alcanza desde la interfaz.
  @override
  Future<AuthResult> signInWithGoogle() async {
    throw UnimplementedError(
      'Inicio de sesión con Google: issue #15 (post-MVP)',
    );
  }

  @override
  Future<void> signOut() {
    return _traducir(() => _client.auth.signOut());
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) {
    return _traducir(
      () => _client.auth.resend(type: sb.OtpType.signup, email: email),
    );
  }

  @override
  AuthSession? get currentSession => _aSesion(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get sessionChanges =>
      _client.auth.onAuthStateChange.map((estado) => _aSesion(estado.session));

  // ---------------------------------------------------------------------------
  // Traducción
  // ---------------------------------------------------------------------------

  AuthSession? _aSesion(sb.Session? sesion) {
    final usuario = sesion?.user;
    if (sesion == null || usuario == null) return null;

    final confirmado = usuario.emailConfirmedAt;

    return AuthSession(
      userId: usuario.id,
      email: usuario.email ?? '',
      emailConfirmedAt:
          confirmado == null ? null : DateTime.tryParse(confirmado),
    );
  }

  /// Corre [accion] y convierte cualquier excepción en un [AuthFailure].
  Future<T> _traducir<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthFailure {
      // Ya está traducida: la lanza signUp para el correo repetido.
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthFailure(_clasificar(e), technicalDetail: e.message);
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      // Sin red, el SDK deja escapar excepciones de socket o de http que no
      // son AuthException. No se pueden capturar por tipo sin importar
      // dart:io, que no compila en web.
      throw AuthFailure(
        _pareceDeRed(e) ? AuthFailureKind.network : AuthFailureKind.unknown,
        technicalDetail: e.toString(),
      );
    }
  }

  /// Mapea el error de Supabase Auth a un caso del dominio.
  ///
  /// Decide por `code`, que es estable, y solo se cae al texto del mensaje
  /// cuando el backend no lo manda.
  AuthFailureKind _clasificar(sb.AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return AuthFailureKind.invalidCredentials;
      case 'email_not_confirmed':
        return AuthFailureKind.emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return AuthFailureKind.emailAlreadyRegistered;
      case 'weak_password':
        return AuthFailureKind.weakPassword;
      case 'validation_failed':
      case 'email_address_invalid':
        return AuthFailureKind.invalidEmail;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AuthFailureKind.tooManyRequests;
    }

    final mensaje = e.message.toLowerCase();
    if (mensaje.contains('invalid login credentials')) {
      return AuthFailureKind.invalidCredentials;
    }
    if (mensaje.contains('not confirmed')) {
      return AuthFailureKind.emailNotConfirmed;
    }
    if (mensaje.contains('already registered')) {
      return AuthFailureKind.emailAlreadyRegistered;
    }
    if (mensaje.contains('password')) return AuthFailureKind.weakPassword;
    return AuthFailureKind.unknown;
  }

  bool _pareceDeRed(Object e) {
    final texto = e.toString().toLowerCase();
    return texto.contains('socketexception') ||
        texto.contains('clientexception') ||
        texto.contains('failed host lookup') ||
        texto.contains('connection') ||
        texto.contains('timeout') ||
        texto.contains('xmlhttprequest');
  }
}
