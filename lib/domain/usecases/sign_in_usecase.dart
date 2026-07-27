// Domain layer: Use case encapsulating one business rule of the app.
//
// Sign-in with email and password. It replaces the `LoginUseCase` of the
// original scaffold, which called `loginWithGoogle()` (issue #8).

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this.repository);

  final AuthRepository repository;

  /// Throws `AuthFailure` if the credentials do not work or the email is
  /// still unconfirmed. The Presentation layer turns it into user-facing copy.
  Future<AuthResult> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(email: email, password: password);
  }
}
