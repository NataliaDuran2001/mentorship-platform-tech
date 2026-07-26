// Capa Domain: Caso de uso que encapsula una regla de negocio de la app.
//
// Inicio de sesión con correo y contraseña. Reemplaza al `LoginUseCase` del
// scaffold original, que llamaba a `loginWithGoogle()` (issue #8).

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this.repository);

  final AuthRepository repository;

  /// Lanza `AuthFailure` si las credenciales no sirven o el correo sigue sin
  /// confirmar. La traducción al español la hace la capa Presentation.
  Future<AuthResult> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(email: email, password: password);
  }
}
