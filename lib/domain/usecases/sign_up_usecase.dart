// Domain layer: Use case encapsulating one business rule of the app.
//
// Registration of a new account with email and password.

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this.repository);

  final AuthRepository repository;

  /// Returns the result exactly as it comes from the repository. With email
  /// confirmation enabled, the normal case is no session and
  /// `requiresEmailConfirmation: true`: the UI has to ask the user to check
  /// her inbox, not assume she is in.
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
