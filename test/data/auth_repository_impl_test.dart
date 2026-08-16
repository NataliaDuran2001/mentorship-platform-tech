// Layer: Data / Test (Unit test for AuthRepositoryImpl error translation).
//
// What is under test is `_translate` + `_classify`: the seam that turns a raw
// Supabase exception into an AuthFailureKind the UI can phrase. It is worth its
// own file because the first beta failed exactly here — the account was never
// created, and the reason reached the user as "Something went wrong".
//
// `signInWithEmail` is the door used for every case: it goes through the same
// `_translate` as the rest and, unlike `signUp`, it does not read
// `SupabaseConfig.emailRedirectTo`, whose `Uri.base.origin` throws outside a
// browser and would fail the test for the wrong reason.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:aspire_app/data/repositories/auth_repository_impl.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';

/// Auth client that throws whatever the test hands it.
class _FakeGoTrueClient implements sb.GoTrueClient {
  Object? errorToThrow;

  /// How long the call takes before answering. For the timeout case.
  Duration? delay;

  @override
  Future<sb.AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (delay != null) await Future<void>.delayed(delay!);
    if (errorToThrow != null) throw errorToThrow!;
    return sb.AuthResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSupabaseClient implements sb.SupabaseClient {
  _FakeSupabaseClient(this.fakeAuth);

  final _FakeGoTrueClient fakeAuth;

  @override
  sb.GoTrueClient get auth => fakeAuth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeGoTrueClient auth;
  late AuthRepositoryImpl repository;

  setUp(() {
    auth = _FakeGoTrueClient();
    repository = AuthRepositoryImpl(
      _FakeSupabaseClient(auth),
      timeout: const Duration(milliseconds: 50),
    );
  });

  Future<AuthFailure> failureFrom(Object error) async {
    auth.errorToThrow = error;
    try {
      await repository.signInWithEmail(email: 'a@b.com', password: 'secret');
    } on AuthFailure catch (failure) {
      return failure;
    }
    fail('expected an AuthFailure, none was thrown');
  }

  group('email quota exhausted', () {
    // This is the beta's bug, reproduced. GoTrue answers a spent mail quota
    // with a numeric `code`, and gotrue-dart only reads that field when it
    // arrives as a String — so `e.code` is null and the old switch fell
    // through to `unknown`.
    test('a 429 with no error code is a rate limit, not an unknown error',
        () async {
      final failure = await failureFrom(
        const sb.AuthApiException(
          'Email rate limit exceeded',
          statusCode: '429',
        ),
      );

      expect(failure.kind, AuthFailureKind.tooManyRequests);
    });

    test('the message alone is enough when even the status is missing',
        () async {
      final failure = await failureFrom(
        const sb.AuthApiException('email rate limit exceeded'),
      );

      expect(failure.kind, AuthFailureKind.tooManyRequests);
    });

    test('the documented error codes keep working', () async {
      for (final code in const [
        'over_email_send_rate_limit',
        'over_request_rate_limit',
      ]) {
        final failure = await failureFrom(
          sb.AuthApiException('too many', statusCode: '429', code: code),
        );

        expect(failure.kind, AuthFailureKind.tooManyRequests, reason: code);
      }
    });
  });

  group('connection failures', () {
    test('a failed fetch is a network problem, not an unknown error', () async {
      // Thrown by gotrue when the request never reached a server: no
      // connection, or CORS. It extends AuthException, which is why it used to
      // reach `_classify`, match nothing and come out as "Something went wrong".
      final failure = await failureFrom(
        sb.AuthRetryableFetchException(message: 'Failed host lookup'),
      );

      expect(failure.kind, AuthFailureKind.network);
    });

    test('a server error is not blamed on the user connection', () async {
      final failure = await failureFrom(
        sb.AuthRetryableFetchException(
          message: 'upstream error',
          statusCode: '503',
        ),
      );

      expect(failure.kind, AuthFailureKind.unknown);
    });

    test('a request that never comes back gives up instead of hanging',
        () async {
      auth.delay = const Duration(seconds: 5);

      // The point is that this completes at all: before the deadline existed,
      // the caller's `finally` never ran and `authLoading` stayed on forever.
      await expectLater(
        repository.signInWithEmail(email: 'a@b.com', password: 'secret'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.kind,
            'kind',
            AuthFailureKind.network,
          ),
        ),
      );
    });
  });

  group('the rest of the classification still holds', () {
    test('wrong password', () async {
      final failure = await failureFrom(
        const sb.AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );

      expect(failure.kind, AuthFailureKind.invalidCredentials);
    });

    test('account not confirmed', () async {
      final failure = await failureFrom(
        const sb.AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        ),
      );

      expect(failure.kind, AuthFailureKind.emailNotConfirmed);
    });

    test('an unrecognized failure is still unknown', () async {
      final failure = await failureFrom(
        const sb.AuthApiException('something else entirely', statusCode: '400'),
      );

      expect(failure.kind, AuthFailureKind.unknown);
    });
  });
}
