// Domain layer: Failure vocabulary of the contracts (pure Dart).
//
// It exists to honour the "no raw Supabase error in sight" rule (issue #9)
// without `presentation` importing supabase_flutter: the Data layer
// translates every SDK `AuthException` into one of these cases, and the
// Presentation layer maps them to user-facing messages.

/// Authentication failure cases the UI needs to tell apart.
enum AuthFailureKind {
  /// Wrong email or password.
  invalidCredentials,

  /// The credentials are valid but the email is still unconfirmed.
  /// The UI offers to resend the confirmation email.
  emailNotConfirmed,

  /// An account with that email already exists.
  emailAlreadyRegistered,

  /// The password does not meet Supabase's minimum policy.
  weakPassword,

  /// The email is not well-formed.
  invalidEmail,

  /// Too many attempts in a row.
  tooManyRequests,

  /// The backend could not be reached.
  network,

  /// The provider is not implemented yet (Google, issue #15).
  notImplemented,

  /// Anything else. The UI shows a generic message.
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, {this.technicalDetail});

  final AuthFailureKind kind;

  /// Original message from the backend. For diagnostics and logs only: it is
  /// never shown as-is to the user.
  final String? technicalDetail;

  @override
  String toString() => 'AuthFailure(${kind.name}): ${technicalDetail ?? '-'}';
}
