// Capa Domain: Caso de uso que encapsula una regla de negocio de la app.
//
// Cierre de sesión.

import '../repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this.repository);

  final AuthRepository repository;

  Future<void> call() => repository.signOut();
}
