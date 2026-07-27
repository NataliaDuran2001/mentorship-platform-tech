// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// Authentication session in domain terms. It exists so that neither
// `presentation` nor `domain` has to know supabase_flutter's `Session`
// type: the Data layer translates one into the other.

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    this.emailConfirmedAt,
  });

  final String userId;
  final String email;

  /// When the email was confirmed, or `null` if it is still unconfirmed.
  final DateTime? emailConfirmedAt;

  bool get isEmailConfirmed => emailConfirmedAt != null;
}

/// Result of a sign-up or a sign-in.
///
/// Email confirmation is enabled (`mailer_autoconfirm: false`), so a
/// successful sign-up returns [session] as `null` and
/// [requiresEmailConfirmation] as `true`. That is not an error: it is the
/// "check your inbox" state the UI has to show.
class AuthResult {
  const AuthResult({
    this.session,
    this.requiresEmailConfirmation = false,
  });

  final AuthSession? session;
  final bool requiresEmailConfirmation;

  /// There is a usable session.
  bool get isSignedIn => session != null;
}
