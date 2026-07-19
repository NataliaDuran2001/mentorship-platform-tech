// Capa Data: Implementación concreta de los repositorios definidos en la capa de Domain.
// Aquí se hacen las peticiones a APIs, Firebase, o bases de datos locales.

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<void> loginWithGoogle() async {
    // Implementación real (ej. FirebaseAuth.instance.signInWithCredential(...))
    await Future.delayed(const Duration(seconds: 2));
  }
}
