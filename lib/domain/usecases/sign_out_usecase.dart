// Domain layer: Use case encapsulating one business rule of the app.
//
// Sign-out.

import '../repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this.repository);

  final AuthRepository repository;

  Future<void> call() => repository.signOut();
}
