// Capa Domain: Caso de uso que encapsula una regla de negocio de la app.
//
// Registro de una cuenta nueva con correo y contraseña.

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this.repository);

  final AuthRepository repository;

  /// Devuelve el resultado tal como viene del repositorio. Con la confirmación
  /// por correo activa, lo normal es `requiresEmailConfirmation: true` y sin
  /// sesión: la UI tiene que pedir que revise su correo, no asumir que entró.
  Future<AuthResult> call({
    required String email,
    required String password,
    String? displayName,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
