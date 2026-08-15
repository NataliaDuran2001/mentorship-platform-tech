// Data layer: Concrete implementation of the OnboardingRepository contract
// against the `profiles` and `onboarding_answers` tables (issue #7).
//
// It takes the SupabaseClient from getIt. Every query is implicitly filtered
// by RLS to the rows of the authenticated user: the explicit `eq('user_id',
// …)` is there anyway, because a query that relies only on the policy to
// avoid bringing other people's data is fragile to read.
//
// It is implemented in full here and not split across #9, #11 and #14 because
// it is a single class: the route guards of #9 need `loadProfile()`, and
// leaving the other three methods throwing would force a second and third
// return to this class. Decision recorded in §9 of the handoff.

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/app_language.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/onboarding_answer.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../models/user_model.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._client);

  final sb.SupabaseClient _client;

  static const String _profilesTable = 'profiles';
  static const String _answersTable = 'onboarding_answers';

  @override
  Future<UserProfile?> loadProfile() async {
    final id = _userId;
    if (id == null) return null;

    return _translate(() async {
      final row = await _client
          .from(_profilesTable)
          .select(UserModel.columns)
          .eq('id', id)
          .maybeSingle();

      // null if the trigger has not created the profile yet. The caller
      // decides whether to retry; no empty profile is invented.
      if (row == null) return null;
      return UserModel.fromJson(row).toEntity();
    });
  }

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {
    final id = _requiredUserId;

    await _translate(() async {
      // Upsert by (user_id, step_key), which is the unique constraint of the
      // table: changing an answer when going back updates the row instead of
      // adding another one. That is what makes the flow resumable (#14).
      await _client.from(_answersTable).upsert(
        <String, dynamic>{
          'user_id': id,
          'step_key': answer.stepKey,
          'value': answer.value,
          'answered_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id, step_key',
      );
    });
  }

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async {
    final id = _userId;
    if (id == null) return const <OnboardingAnswer>[];

    return _translate(() async {
      final rows = await _client
          .from(_answersTable)
          .select('step_key, value, answered_at')
          .eq('user_id', id);

      return rows
          .map(
            (row) => OnboardingAnswer(
              stepKey: row['step_key'] as String,
              value: row['value'] as String,
              answeredAt: DateTime.tryParse(
                row['answered_at'] as String? ?? '',
              ),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    final id = _requiredUserId;

    return _translate(() async {
      final row = await _client
          .from(_profilesTable)
          .update(<String, dynamic>{
            'experience_level': experienceLevel?.slug,
            'track_id': track.slug,
            'learning_goal': learningGoal?.slug,
            'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select(UserModel.columns)
          .single();

      return UserModel.fromJson(row).toEntity();
    });
  }

  @override
  Future<UserProfile> updateLanguage({required AppLanguage language}) async {
    final id = _requiredUserId;

    return _translate(() async {
      final row = await _client
          .from(_profilesTable)
          .update(<String, dynamic>{'language': language.slug})
          .eq('id', id)
          .select(UserModel.columns)
          .single();

      return UserModel.fromJson(row).toEntity();
    });
  }

  @override
  Future<UserProfile> updateLearningGoal({required LearningGoal goal}) async {
    final id = _requiredUserId;

    return _translate(() async {
      final row = await _client
          .from(_profilesTable)
          .update(<String, dynamic>{'learning_goal': goal.slug})
          .eq('id', id)
          .select(UserModel.columns)
          .single();

      return UserModel.fromJson(row).toEntity();
    });
  }

  // ---------------------------------------------------------------------------

  String? get _userId => _client.auth.currentUser?.id;

  /// Same as [_userId] but fails when there is no session, for the writes.
  ///
  /// Without a session the RLS policy would reject the row anyway, but with a
  /// Postgres error that says nothing useful. Better to fail here and with a
  /// known case.
  String get _requiredUserId {
    final id = _userId;
    if (id == null) {
      throw const AuthFailure(
        AuthFailureKind.invalidCredentials,
        technicalDetail: 'No active session while writing the onboarding',
      );
    }
    return id;
  }

  /// Translates the backend errors into AuthFailure, just like
  /// AuthRepositoryImpl: presentation does not import supabase_flutter.
  Future<T> _translate<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } on sb.AuthException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      final text = e.toString().toLowerCase();
      final isNetwork = text.contains('socketexception') ||
          text.contains('clientexception') ||
          text.contains('failed host lookup') ||
          text.contains('connection') ||
          text.contains('timeout') ||
          text.contains('xmlhttprequest');

      throw AuthFailure(
        isNetwork ? AuthFailureKind.network : AuthFailureKind.unknown,
        technicalDetail: e.toString(),
      );
    }
  }
}
