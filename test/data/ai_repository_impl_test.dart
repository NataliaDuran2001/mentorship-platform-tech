// Layer: Presentation / Test (Unit test for Data Layer: AiRepositoryImpl)

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aspire_app/data/repositories/ai_repository_impl.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/failures/ai_failure.dart';

/// Fake FunctionsClient to intercept calls to Edge Functions without network.
class _FakeFunctionsClient implements FunctionsClient {
  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int responseStatus = 200;
  dynamic responseData;
  Exception? errorToThrow;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? queryParameters,
    Iterable<MultipartFile>? files,
    String? region,
  }) async {
    lastFunctionName = functionName;
    lastBody = body as Map<String, dynamic>?;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return FunctionResponse(
      status: responseStatus,
      data: responseData,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake SupabaseClient that supplies the _FakeFunctionsClient.
class _FakeSupabaseClient implements SupabaseClient {
  _FakeSupabaseClient(this.fakeFunctions);

  final _FakeFunctionsClient fakeFunctions;

  @override
  FunctionsClient get functions => fakeFunctions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeFunctionsClient fakeFunctions;
  late _FakeSupabaseClient fakeClient;
  late AiRepositoryImpl repository;

  setUp(() {
    fakeFunctions = _FakeFunctionsClient();
    fakeClient = _FakeSupabaseClient(fakeFunctions);
    repository = AiRepositoryImpl(fakeClient);
  });

  group('AiRepositoryImpl.analyzeProfile', () {
    test('parses a successful response correctly', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'recommendedTrack': 'frontend',
        'reasoning': 'You enjoy visual design and UI.',
        'confidence': 0.9,
        'alternatives': [
          {'track': 'backend', 'reason': 'Good logic skills too.'}
        ],
      };

      final answers = [
        const OnboardingAnswer(stepKey: 'quiz_1', value: 'frontend'),
      ];

      final result = await repository.analyzeProfile(
        answers: answers,
        experienceLevel: ExperienceLevel.student,
        learningGoal: LearningGoal.firstJob,
      );

      expect(fakeFunctions.lastFunctionName, 'analyze-profile');
      expect(fakeFunctions.lastBody?['experienceLevel'], 'student');
      expect(fakeFunctions.lastBody?['learningGoal'], 'first_job');
      expect(result.track, RoadmapTrack.frontend);
      expect(result.reasoning, 'You enjoy visual design and UI.');
      expect(result.confidence, 0.9);
      expect(result.wasTie, isTrue); // because alternatives is not empty
      expect(result.alternatives.length, 1);
      expect(result.alternatives.first.track, RoadmapTrack.backend);
    });

    test('throws AiFailure.serviceUnavailable on non-200 status', () async {
      fakeFunctions.responseStatus = 502;
      fakeFunctions.responseData = {'error': 'AI service unavailable'};

      expect(
        () => repository.analyzeProfile(answers: []),
        throwsA(
          isA<AiFailure>().having(
            (f) => f.kind,
            'kind',
            AiFailureKind.serviceUnavailable,
          ),
        ),
      );
    });

    test('throws AiFailure.invalidResponse when track is missing', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'reasoning': 'No track specified',
      };

      expect(
        () => repository.analyzeProfile(answers: []),
        throwsA(
          isA<AiFailure>().having(
            (f) => f.kind,
            'kind',
            AiFailureKind.invalidResponse,
          ),
        ),
      );
    });
  });

  group('AiRepositoryImpl.generateDailyBrief', () {
    test('returns brief text on success', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'brief': 'Welcome back! Today focus on HTML tags.',
      };

      final brief = await repository.generateDailyBrief(
        userId: 'user-123',
        trackSlug: 'frontend',
        experienceLevelSlug: 'student',
        learningGoalSlug: 'first_job',
        completedTopics: 1,
        totalTopics: 3,
      );

      expect(fakeFunctions.lastFunctionName, 'daily-brief');
      expect(brief, 'Welcome back! Today focus on HTML tags.');
    });

    test('throws AiFailure.invalidResponse when brief field is null', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = <String, dynamic>{};

      expect(
        () => repository.generateDailyBrief(
          userId: 'user-123',
          trackSlug: 'frontend',
          experienceLevelSlug: null,
          learningGoalSlug: null,
          completedTopics: 0,
          totalTopics: 3,
        ),
        throwsA(
          isA<AiFailure>().having(
            (f) => f.kind,
            'kind',
            AiFailureKind.invalidResponse,
          ),
        ),
      );
    });
  });

  group('AiRepositoryImpl.generateLabHint', () {
    test('returns hint text on success', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'hint': 'Try using the <main> tag instead of <div>.',
      };

      final hint = await repository.generateLabHint(
        challengeQuestion: 'Which tag is semantic?',
        challengeType: 'multiple_choice',
        attemptCount: 2,
        userContext: null,
      );

      expect(fakeFunctions.lastFunctionName, 'lab-hint');
      expect(hint, 'Try using the <main> tag instead of <div>.');
    });
  });

  group('AiRepositoryImpl.generateRoadmapCoachMessage', () {
    test('returns coach message on success', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'message': 'Keep going! You are 33% done with frontend.',
      };

      final msg = await repository.generateRoadmapCoachMessage(
        trackSlug: 'frontend',
        learningGoalSlug: 'first_job',
        progressFraction: 0.33,
        nextTopicTitle: 'CSS Basics',
      );

      expect(fakeFunctions.lastFunctionName, 'roadmap-coach');
      expect(fakeFunctions.lastBody?['progressPercent'], 33);
      expect(msg, 'Keep going! You are 33% done with frontend.');
    });
  });
}
