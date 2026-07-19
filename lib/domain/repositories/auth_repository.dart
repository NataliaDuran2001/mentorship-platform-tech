// Capa Domain: Contratos (interfaces) de los repositorios.
// Define QUÉ se puede hacer con los datos, pero no CÓMO se hace.

abstract class AuthRepository {
  Future<void> loginWithGoogle();
}
