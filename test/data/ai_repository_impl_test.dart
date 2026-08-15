// Layer: Presentation / Test (Unit test for Data Layer: AiRepositoryImpl)

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aspire_app/data/repositories/ai_repository_impl.dart';
import 'package:aspire_app/domain/entities/app_language.dart';
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
        language: AppLanguage.es,
      );

      expect(fakeFunctions.lastFunctionName, 'analyze-profile');
      expect(fakeFunctions.lastBody?['experienceLevel'], 'student');
      expect(fakeFunctions.lastBody?['learningGoal'], 'first_job');
      expect(fakeFunctions.lastBody?['language'], 'es');
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
        () => repository.analyzeProfile(answers: [], language: AppLanguage.en),
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
        () => repository.analyzeProfile(answers: [], language: AppLanguage.en),
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
        language: AppLanguage.en,
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
          language: AppLanguage.en,
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
        language: AppLanguage.en,
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
        language: AppLanguage.en,
      );

      expect(fakeFunctions.lastFunctionName, 'roadmap-coach');
      expect(fakeFunctions.lastBody?['progressPercent'], 33);
      expect(msg, 'Keep going! You are 33% done with frontend.');
    });
  });

  group('AiRepositoryImpl.generateWelcomeMessage', () {
    test('returns the headline on success', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {'message': 'STILL BUILDING MOMENTUM'};

      final msg = await repository.generateWelcomeMessage(
        displayName: 'Ana',
        trackSlug: 'frontend',
        learningGoalSlug: 'first_job',
        progressFraction: 0.5,
        language: AppLanguage.en,
      );

      expect(fakeFunctions.lastFunctionName, 'welcome-message');
      expect(fakeFunctions.lastBody?['displayName'], 'Ana');
      expect(msg, 'STILL BUILDING MOMENTUM');
    });

    test('throws AiFailure.invalidResponse when message field is missing', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = <String, dynamic>{};

      expect(
        () => repository.generateWelcomeMessage(
          displayName: 'Ana',
          trackSlug: null,
          learningGoalSlug: null,
          progressFraction: 0,
          language: AppLanguage.en,
        ),
        throwsA(
          isA<AiFailure>().having((f) => f.kind, 'kind', AiFailureKind.invalidResponse),
        ),
      );
    });
  });

  group('AiRepositoryImpl.translateTopics', () {
    test('calls translate-content with sourceTable "topics" and maps the result', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'translations': [
          {
            'sourceId': 'topic-1',
            'content': {'title': 'Básico', 'description': 'Los fundamentos.'},
          },
        ],
      };

      final result = await repository.translateTopics(
        topicIds: ['topic-1'],
        language: AppLanguage.es,
      );

      expect(fakeFunctions.lastFunctionName, 'translate-content');
      expect(fakeFunctions.lastBody?['language'], 'es');
      final items = fakeFunctions.lastBody?['items'] as List;
      expect(items.single, {'sourceTable': 'topics', 'sourceId': 'topic-1'});
      expect(result['topic-1']?.title, 'Básico');
      expect(result['topic-1']?.description, 'Los fundamentos.');
    });

    test('returns an empty map without calling the function when topicIds is empty', () async {
      final result = await repository.translateTopics(
        topicIds: const [],
        language: AppLanguage.es,
      );

      expect(fakeFunctions.lastFunctionName, isNull);
      expect(result, isEmpty);
    });

    test('omits ids the server could not translate instead of throwing', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {'translations': <dynamic>[]};

      final result = await repository.translateTopics(
        topicIds: ['topic-1'],
        language: AppLanguage.es,
      );

      expect(result, isEmpty);
    });
  });

  group('AiRepositoryImpl.translateTheoryChallenges', () {
    test('calls translate-content with sourceTable "lab_challenges" and maps blocks', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'translations': [
          {
            'sourceId': 'challenge-1',
            'content': {
              'question': '¿Qué es HTML?',
              'blocks': [
                {'type': 'paragraph', 'text': 'HTML da significado al contenido.'},
                {'type': 'code', 'text': '<p>hola</p>', 'language': 'html'},
              ],
              'keyTakeaway': 'HTML describe significado, no apariencia.',
            },
          },
        ],
      };

      final result = await repository.translateTheoryChallenges(
        challengeIds: ['challenge-1'],
        language: AppLanguage.es,
      );

      expect(fakeFunctions.lastFunctionName, 'translate-content');
      final items = fakeFunctions.lastBody?['items'] as List;
      expect(items.single, {'sourceTable': 'lab_challenges', 'sourceId': 'challenge-1'});

      final translation = result['challenge-1']!;
      expect(translation.question, '¿Qué es HTML?');
      expect(translation.blocks, hasLength(2));
      expect(translation.blocks[1].text, '<p>hola</p>');
      expect(translation.keyTakeaway, 'HTML describe significado, no apariencia.');
    });
  });

  group('AiRepositoryImpl.translateExerciseChallenges', () {
    test('maps question/description/items, keeping the technical items untouched', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'translations': [
          {
            'sourceId': 'exercise-1',
            'content': {
              'question': '¿Qué lenguaje usarías para cambiar el color de un botón?',
              'description': 'Piensa en cuál de los tres es responsable de la apariencia.',
              'items': {
                'html': 'HTML, porque ahí están escritos los botones',
                'css': 'CSS, porque el color es presentación',
                'js': 'JavaScript, porque cambia la página',
                'server': 'El servidor, porque envía los archivos',
              },
            },
          },
        ],
      };

      final result = await repository.translateExerciseChallenges(
        challengeIds: ['exercise-1'],
        language: AppLanguage.es,
      );

      expect(fakeFunctions.lastFunctionName, 'translate-content');
      final items = fakeFunctions.lastBody?['items'] as List;
      expect(items.single, {'sourceTable': 'lab_challenges', 'sourceId': 'exercise-1'});

      final translation = result['exercise-1']!;
      expect(translation.question, '¿Qué lenguaje usarías para cambiar el color de un botón?');
      expect(translation.items?['css'], 'CSS, porque el color es presentación');
      // The option id ("css") is what decides the correct answer — the
      // translation must never rename or drop it.
      expect(translation.items?.keys, containsAll(['html', 'css', 'js', 'server']));
    });

    test('fill_blank translations carry no items, only question/description', () async {
      fakeFunctions.responseStatus = 200;
      fakeFunctions.responseData = {
        'translations': [
          {
            'sourceId': 'fillblank-1',
            'content': {
              'question': 'Escribe un encabezado y un párrafo.',
              'description': 'Recuerda cerrar cada etiqueta.',
            },
          },
        ],
      };

      final result = await repository.translateExerciseChallenges(
        challengeIds: ['fillblank-1'],
        language: AppLanguage.es,
      );

      expect(result['fillblank-1']?.items, isNull);
      expect(result['fillblank-1']?.question, 'Escribe un encabezado y un párrafo.');
    });
  });
}
