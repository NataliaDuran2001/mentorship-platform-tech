// Domain layer: Contract (interface) of the authentication repository.
// It defines WHAT can be done, not HOW. The implementation lives in `data`.
//
// Every method that fails throws `AuthFailure` (never the raw backend
// exception). The real implementation belongs to issue #9.

import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Registers a new account with email and password.
  ///
  /// With email confirmation enabled the result carries `session` as `null`
  /// and `requiresEmailConfirmation` as `true`. That is success, not failure.
  ///
  /// Throws `AuthFailure` with `emailAlreadyRegistered`, `weakPassword` or
  /// `invalidEmail` as appropriate.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in with email and password.
  ///
  /// Throws `AuthFailure` with `invalidCredentials` if they do not match and
  /// with `emailNotConfirmed` if the account exists but is unconfirmed.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs in with Google.
  ///
  /// Reserved for issue #15 (`fase:post-mvp`). The MVP is email/password, so
  /// the implementation throws `UnimplementedError`. It is in the contract
  /// from now on so that #15 is purely additive.
  Future<AuthResult> signInWithGoogle();

  /// Closes the current session. Idempotent: with no session it does nothing.
  Future<void> signOut();

  /// Resends the confirmation email of an unconfirmed account.
  Future<void> resendConfirmationEmail({required String email});

  /// Current session, or `null` if there is none. Synchronous read: the SDK
  /// restores the persisted session before the UI starts.
  AuthSession? get currentSession;

  /// Session changes: login, logout, token refresh and email confirmation.
  /// Emits `null` when the session is closed.
  Stream<AuthSession?> get sessionChanges;
}
