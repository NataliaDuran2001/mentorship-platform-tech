// Capa Domain: Casos de uso que encapsulan una regla de negocio específica de la aplicación.
// En este caso, la lógica de negocio para iniciar sesión.

import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);
  
  Future<void> call() async {
    return await repository.loginWithGoogle();
  }
}
