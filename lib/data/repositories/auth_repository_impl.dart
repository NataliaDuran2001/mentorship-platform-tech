// Data layer: Concrete implementation of the AuthRepository contract against
// Supabase Auth.
//
// It takes the SupabaseClient through the constructor —getIt injects it—
// and never calls Supabase.instance.client.
//
// Its other responsibility is translating: no SDK exception leaves this class.
// Everything that fails comes out as an AuthFailure, with an AuthFailureKind
// case that the Presentation layer turns into a message for the user. That is
// what makes it possible to honour "no raw Supabase error in sight" without
// presentation importing supabase_flutter.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/config/supabase_config.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client, {Duration timeout = defaultTimeout})
      : _timeout = timeout;

  final sb.SupabaseClient _client;

  /// Deadline for every authentication call.
  ///
  /// It is set here and not on the shared http client of `Supabase.initialize`
  /// on purpose: that client also carries the Edge Function calls, and the AI
  /// ones legitimately take tens of seconds. Authentication does not — and a
  /// request with no deadline is what let a single stalled sign-up leave
  /// `authLoading` on forever, with the spinner covering both the sign-up and
  /// the login screen.
  ///
  /// It is a parameter only so a test can use a short one; production always
  /// takes [defaultTimeout].
  static const Duration defaultTimeout = Duration(seconds: 30);

  final Duration _timeout;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _translate(() async {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Where the link in the email lands (issue #34). Without this,
        // Supabase falls back to the Site URL and the app has no way to tell
        // a confirmation from a plain visit.
        emailRedirectTo: SupabaseConfig.emailRedirectTo,
        // The handle_new_user() trigger reads it to fill
        // profiles.display_name.
        data: displayName == null || displayName.isEmpty
            ? null
            : <String, dynamic>{'display_name': displayName},
      );

      // With email enumeration protection enabled, signing up with an email
      // that already exists does NOT return an error: it returns a user with
      // an empty identity list. Without this check the UI would say "check
      // your email" to someone who already has an account and will never
      // receive anything.
      final identities = response.user?.identities;
      if (identities != null && identities.isEmpty) {
        throw const AuthFailure(AuthFailureKind.emailAlreadyRegistered);
      }

      // With mailer_autoconfirm set to false this is the normal path: user
      // created, no session, waiting for the email confirmation. It is
      // success, not failure.
      return AuthResult(
        session: _toSession(response.session),
        requiresEmailConfirmation: response.session == null,
      );
    });
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _translate(() async {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResult(session: _toSession(response.session));
    });
  }

  /// Reserved for issue #15 (`fase:post-mvp`).
  ///
  /// It throws `UnimplementedError` on purpose, and not an `AuthFailure`: it
  /// is not a runtime failure the UI should show, it is code that does not
  /// exist yet. The login screen keeps the Google button disabled, so this
  /// path is not reachable from the interface.
  @override
  Future<AuthResult> signInWithGoogle() async {
    throw UnimplementedError(
      'Sign in with Google: issue #15 (post-MVP)',
    );
  }

  @override
  Future<void> signOut() {
    return _translate(() => _client.auth.signOut());
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) {
    return _translate(
      () => _client.auth.resend(
        type: sb.OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseConfig.emailRedirectTo,
      ),
    );
  }

  @override
  Future<void> requestPasswordRecovery({required String email}) {
    return _translate(
      () => _client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordRecoveryRedirectTo,
      ),
    );
  }

  @override
  Future<void> confirmPasswordRecovery({required String tokenHash}) {
    return _translate(
      () => _client.auth.verifyOTP(
        type: sb.OtpType.recovery,
        tokenHash: tokenHash,
      ),
    );
  }

  @override
  Future<void> updatePassword({required String newPassword}) {
    return _translate(
      () => _client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      ),
    );
  }

  @override
  AuthSession? get currentSession => _toSession(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get sessionChanges =>
      _client.auth.onAuthStateChange.map((state) => _toSession(state.session));

  // ---------------------------------------------------------------------------
  // Translation
  // ---------------------------------------------------------------------------

  AuthSession? _toSession(sb.Session? session) {
    final user = session?.user;
    if (session == null || user == null) return null;

    final confirmedAt = user.emailConfirmedAt;

    return AuthSession(
      userId: user.id,
      email: user.email ?? '',
      emailConfirmedAt:
          confirmedAt == null ? null : DateTime.tryParse(confirmedAt),
    );
  }

  /// Runs [action] under [_timeout] and converts any exception into an
  /// [AuthFailure].
  Future<T> _translate<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on TimeoutException {
      // The request never came back. From the user's side that is
      // indistinguishable from having no connection, and the message —"check
      // your connection and try again"— is the right advice either way.
      throw const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'auth request timed out',
      );
    } on AuthFailure {
      // Already translated: signUp throws it for the duplicated email.
      rethrow;
    } on sb.AuthRetryableFetchException catch (e) {
      // It has to be caught *before* AuthException, which it extends. Without
      // this branch a dropped connection or a CORS misconfiguration reached
      // `_classify`, matched none of its cases and came out as "unknown" —
      // "Something went wrong" for what is plainly "we could not connect".
      //
      // gotrue throws it in two situations, and only one of them is the
      // network: a failed fetch (no status code) and a 5xx (status code
      // present). A server error is not the user's connection, so it keeps
      // saying "try again in a moment" instead of blaming her wifi.
      throw AuthFailure(
        e.statusCode == null
            ? AuthFailureKind.network
            : AuthFailureKind.unknown,
        technicalDetail: e.message,
      );
    } on sb.AuthException catch (e) {
      throw AuthFailure(_classify(e), technicalDetail: e.message);
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      // Without network, the SDK lets socket or http exceptions escape that
      // are not AuthException. They cannot be caught by type without
      // importing dart:io, which does not compile on web.
      throw AuthFailure(
        _looksLikeNetwork(e)
            ? AuthFailureKind.network
            : AuthFailureKind.unknown,
        technicalDetail: e.toString(),
      );
    }
  }

  /// Maps the Supabase Auth error to a domain case.
  ///
  /// It decides by `code`, which is stable, and only falls back to the HTTP
  /// status and the message text when the backend does not send it.
  AuthFailureKind _classify(sb.AuthException e) {
    // Rate limiting is checked before the `code` switch because that is the
    // case where `code` is the least trustworthy. GoTrue answers a spent email
    // quota with `{"code": 429, "error_code": "over_email_send_rate_limit"}`,
    // and gotrue-dart only reads `code` when it arrives as a *string*: a
    // numeric 429 leaves `e.code` null and the error fell through to
    // "unknown". That is exactly what the beta hit — the whole project shares
    // one small hourly quota on Supabase's built-in mailer, so the second
    // person to sign up within the hour was told "Something went wrong"
    // instead of "wait a few minutes".
    //
    // `statusCode` is the reliable signal: gotrue fills it from the HTTP
    // response on every AuthApiException, whatever the body looks like.
    if (e.statusCode == '429' ||
        e.message.toLowerCase().contains('rate limit')) {
      return AuthFailureKind.tooManyRequests;
    }

    switch (e.code) {
      case 'invalid_credentials':
      case 'invalid_grant':
        return AuthFailureKind.invalidCredentials;
      case 'email_not_confirmed':
        return AuthFailureKind.emailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return AuthFailureKind.emailAlreadyRegistered;
      case 'weak_password':
        return AuthFailureKind.weakPassword;
      case 'validation_failed':
      case 'email_address_invalid':
        return AuthFailureKind.invalidEmail;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AuthFailureKind.tooManyRequests;
      case 'same_password':
        return AuthFailureKind.samePassword;
      // updateUser without a live session, or a recovery token_hash that
      // expired or was already used (issue #57).
      case 'session_expired':
      case 'session_not_found':
      case 'refresh_token_not_found':
      case 'otp_expired':
        return AuthFailureKind.sessionExpired;
    }

    // AuthSessionMissingException carries no stable code; its message does.
    // And older backends report the spent token_hash by text alone.
    final lower = e.message.toLowerCase();
    if (lower.contains('session missing') ||
        lower.contains('invalid or has expired')) {
      return AuthFailureKind.sessionExpired;
    }

    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return AuthFailureKind.invalidCredentials;
    }
    if (message.contains('not confirmed')) {
      return AuthFailureKind.emailNotConfirmed;
    }
    if (message.contains('already registered')) {
      return AuthFailureKind.emailAlreadyRegistered;
    }
    if (message.contains('password')) return AuthFailureKind.weakPassword;
    return AuthFailureKind.unknown;
  }

  bool _looksLikeNetwork(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('timeout') ||
        text.contains('xmlhttprequest');
  }
}
