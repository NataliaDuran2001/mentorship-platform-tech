// Data layer: Implementation of InterviewRepository.
//
// generateQuestions/analyzeSession go through Supabase Edge Functions, which
// proxy to the Kimi3 API (kimi-k3 by Moonshot AI), the same way
// AiRepositoryImpl does. Neither call is cached: generate-interview-questions
// must vary between calls by design, and analyze-interview-session grades a
// unique set of answers every time.
//
// saveSession/loadSessions are plain table reads/writes against
// `interview_sessions` instead — no Edge Function involved, same shape as
// OnboardingRepositoryImpl's saveAnswer/loadAnswers.

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/app_language.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/interview_answer_feedback.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/interview_session_feedback.dart';
import '../../domain/entities/interview_session_record.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/failures/ai_failure.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/interview_repository.dart';
import '../models/interview_session_model.dart';

class InterviewRepositoryImpl implements InterviewRepository {
  const InterviewRepositoryImpl(this._client);

  final sb.SupabaseClient _client;

  static const String _sessionsTable = 'interview_sessions';

  // ---------------------------------------------------------------------------
  // generateQuestions
  // ---------------------------------------------------------------------------

  @override
  Future<List<InterviewQuestion>> generateQuestions({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
    String? desiredRole,
    required AppLanguage language,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-interview-questions',
        body: {
          'trackSlug': track.slug,
          'experienceLevelSlug': experienceLevel?.slug,
          'learningGoalSlug': learningGoal?.slug,
          'desiredRole': desiredRole,
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail:
              'generate-interview-questions returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final rawQuestions = data['questions'] as List<dynamic>?;
      if (rawQuestions == null || rawQuestions.isEmpty) {
        throw const AiFailure(
          AiFailureKind.invalidResponse,
          technicalDetail: 'questions field is missing or empty',
        );
      }

      return [
        for (var i = 0; i < rawQuestions.length; i++)
          _parseQuestion(rawQuestions[i] as Map<String, dynamic>, i),
      ];
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  InterviewQuestion _parseQuestion(Map<String, dynamic> data, int index) {
    final prompt = data['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      throw const AiFailure(
        AiFailureKind.invalidResponse,
        technicalDetail: 'question prompt is missing',
      );
    }
    final category = data['category'] as String?;
    return InterviewQuestion(
      id: 'q-$index',
      prompt: prompt,
      category: (category == null || category.isEmpty) ? 'technical' : category,
    );
  }

  // ---------------------------------------------------------------------------
  // analyzeSession
  // ---------------------------------------------------------------------------

  @override
  Future<InterviewSessionFeedback> analyzeSession({
    required List<InterviewQuestion> questions,
    required Map<String, String> answers,
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    required AppLanguage language,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'analyze-interview-session',
        body: {
          'trackSlug': track.slug,
          'experienceLevelSlug': experienceLevel?.slug,
          'language': language.slug,
          'items': [
            for (final question in questions)
              {
                'questionId': question.id,
                'questionPrompt': question.prompt,
                'category': question.category,
                'answerText': answers[question.id],
              },
          ],
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail:
              'analyze-interview-session returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return _parseSessionFeedback(data, questions);
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  InterviewSessionFeedback _parseSessionFeedback(
    Map<String, dynamic> data,
    List<InterviewQuestion> questions,
  ) {
    final overallSummary = data['overallSummary'] as String?;
    final rawResults = data['results'] as List<dynamic>?;
    if (overallSummary == null ||
        overallSummary.isEmpty ||
        rawResults == null ||
        rawResults.length != questions.length) {
      throw const AiFailure(
        AiFailureKind.invalidResponse,
        technicalDetail: 'overallSummary or results is missing/incomplete',
      );
    }

    final questionIds = questions.map((q) => q.id).toSet();
    final results = [
      for (final raw in rawResults)
        _parseAnswerFeedback(raw as Map<String, dynamic>, questionIds),
    ];

    return InterviewSessionFeedback(
      overallSummary: overallSummary,
      results: results,
    );
  }

  InterviewAnswerFeedback _parseAnswerFeedback(
    Map<String, dynamic> data,
    Set<String> questionIds,
  ) {
    final questionId = data['questionId'] as String?;
    final summary = data['summary'] as String?;
    final score = (data['score'] as num?)?.toInt();
    if (questionId == null ||
        !questionIds.contains(questionId) ||
        summary == null ||
        summary.isEmpty ||
        score == null) {
      throw const AiFailure(
        AiFailureKind.invalidResponse,
        technicalDetail: 'questionId, summary or score is missing/invalid',
      );
    }

    final strengths = (data['strengths'] as List<dynamic>? ?? [])
        .map((s) => s.toString())
        .toList();
    final improvements = (data['improvements'] as List<dynamic>? ?? [])
        .map((s) => s.toString())
        .toList();

    return InterviewAnswerFeedback(
      questionId: questionId,
      summary: summary,
      strengths: strengths,
      improvements: improvements,
      score: score.clamp(0, 100),
    );
  }

  // ---------------------------------------------------------------------------
  // saveSession / loadSessions
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSession({
    required RoadmapTrack track,
    String? desiredRole,
    required List<InterviewQuestion> questions,
    required Map<String, String> answers,
    required InterviewSessionFeedback feedback,
  }) async {
    final id = _requiredUserId;
    final scores = feedback.results.map((f) => f.score);
    final averageScore =
        scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round();

    await _translate(() async {
      await _client.from(_sessionsTable).insert(<String, dynamic>{
        'user_id': id,
        'track_id': track.slug,
        'desired_role': desiredRole,
        'average_score': averageScore,
        'overall_summary': feedback.overallSummary,
        'questions': [
          for (final q in questions)
            {'id': q.id, 'prompt': q.prompt, 'category': q.category},
        ],
        'answers': answers,
        'feedback': [
          for (final f in feedback.results)
            {
              'questionId': f.questionId,
              'summary': f.summary,
              'strengths': f.strengths,
              'improvements': f.improvements,
              'score': f.score,
            },
        ],
      });
    });
  }

  @override
  Future<List<InterviewSessionRecord>> loadSessions() async {
    final id = _userId;
    if (id == null) return const <InterviewSessionRecord>[];

    return _translate(() async {
      final rows = await _client
          .from(_sessionsTable)
          .select(InterviewSessionModel.columns)
          .eq('user_id', id)
          .order('created_at', ascending: false);

      return [
        for (final row in rows) InterviewSessionModel.fromJson(row).toEntity(),
      ];
    });
  }

  // ---------------------------------------------------------------------------

  String? get _userId => _client.auth.currentUser?.id;

  /// Same as [_userId] but fails when there is no session, for the writes.
  String get _requiredUserId {
    final id = _userId;
    if (id == null) {
      throw const AuthFailure(
        AuthFailureKind.invalidCredentials,
        technicalDetail: 'No active session while saving an interview session',
      );
    }
    return id;
  }

  /// Translates the backend errors into AuthFailure, same as
  /// OnboardingRepositoryImpl: presentation does not import supabase_flutter.
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
