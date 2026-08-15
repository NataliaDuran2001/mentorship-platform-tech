// Unit tests of the only real business logic of Module 1 (issue #8, AC3).
// They do not mount Flutter: the domain layer is pure Dart.
//
// AI-First: The use case is now async and tries Kimi3 first. These tests
// exercise the deterministic vote-count **fallback** by providing a stub
// AiRepository that always throws AiFailure (simulating the AI being offline).

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/app_language.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/track_recommendation.dart';
import 'package:aspire_app/domain/failures/ai_failure.dart';
import 'package:aspire_app/domain/repositories/ai_repository.dart';
import 'package:aspire_app/domain/usecases/recommend_track_usecase.dart';

/// Stub that always fails so the vote-count fallback is exercised.
class _OfflineAiRepository implements AiRepository {
  const _OfflineAiRepository();

  @override
  Future<TrackRecommendation> analyzeProfile({
    required List<OnboardingAnswer> answers,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
    required AppLanguage language,
  }) async =>
      throw const AiFailure(AiFailureKind.network);

  @override
  Future<String> generateDailyBrief({
    required String userId,
    required String trackSlug,
    required String? experienceLevelSlug,
    required String? learningGoalSlug,
    required int completedTopics,
    required int totalTopics,
    required AppLanguage language,
  }) async =>
      throw const AiFailure(AiFailureKind.network);

  @override
  Future<String> generateLabHint({
    required String challengeQuestion,
    required String challengeType,
    required int attemptCount,
    required String? userContext,
    required AppLanguage language,
  }) async =>
      throw const AiFailure(AiFailureKind.network);

  @override
  Future<String> generateRoadmapCoachMessage({
    required String trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required String? nextTopicTitle,
    required AppLanguage language,
  }) async =>
      throw const AiFailure(AiFailureKind.network);
}

/// Answers of the guided quiz, numbered from 1 as in issue #12.
List<OnboardingAnswer> _quiz(List<String> values) => [
      for (var i = 0; i < values.length; i++)
        OnboardingAnswer(
          stepKey: OnboardingKeys.quizQuestion(i + 1),
          value: values[i],
        ),
    ];

void main() {
  // Use the offline stub: these tests verify the vote-count fallback.
  const usecase = RecommendTrackUseCase(_OfflineAiRepository());

  group('every track can be recommended', () {
    for (final track in RoadmapTrack.values) {
      test('a majority of votes for ${track.slug} recommends ${track.slug}',
          () async {
        // 2 votes for the track under test and 1 for a different one: a clear
        // majority.
        final other = RoadmapTrack.values.firstWhere((t) => t != track);
        final result =
            await usecase(_quiz([track.slug, track.slug, other.slug]));

        expect(result.track, track);
        expect(result.wasTie, isFalse);
        expect(result.hasRecommendation, isTrue);
        expect(result.scores[track], 2);
        expect(result.scores[other], 1);
      });
    }
  });

  test('with no answers there is no recommendation', () async {
    final result = await usecase(const <OnboardingAnswer>[]);

    expect(result.hasRecommendation, isFalse);
    expect(result.track, isNull);
    expect(result.wasTie, isFalse);
    // The three tracks present at zero: the UI can paint the breakdown anyway.
    expect(result.scores.length, RoadmapTrack.values.length);
    expect(result.scores.values.every((v) => v == 0), isTrue);
  });

  test('answers that do not map to a track do not count as votes', () async {
    // Level, goal and "I'm not sure yet": none of them is a track.
    final result = await usecase(const [
      OnboardingAnswer(
        stepKey: OnboardingKeys.experienceLevel,
        value: 'student',
      ),
      OnboardingAnswer(stepKey: OnboardingKeys.goal, value: 'first_job'),
      OnboardingAnswer(
        stepKey: OnboardingKeys.track,
        value: OnboardingKeys.unknownTrackValue,
      ),
    ]);

    expect(result.hasRecommendation, isFalse);
    expect(result.scores.values.every((v) => v == 0), isTrue);
  });

  test('a three-way tie: frontend wins and it is flagged as a tie', () async {
    final result = await usecase(_quiz([
      RoadmapTrack.backend.slug,
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.frontend.slug,
    ]));

    expect(result.wasTie, isTrue);
    expect(result.track, RoadmapTrack.frontend);
  });

  test('a tie without frontend: backend wins by declaration order', () async {
    final result = await usecase(_quiz([
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.backend.slug,
    ]));

    expect(result.wasTie, isTrue);
    expect(result.track, RoadmapTrack.backend);
  });

  test('the tie-break is deterministic: arrival order does not change it',
      () async {
    final a = await usecase(_quiz([
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.backend.slug,
    ]));
    final b = await usecase(_quiz([
      RoadmapTrack.backend.slug,
      RoadmapTrack.infrastructure.slug,
    ]));

    expect(a.track, b.track);
  });

  test('a single answer is enough and is not a tie', () async {
    final result = await usecase(_quiz([RoadmapTrack.infrastructure.slug]));

    expect(result.track, RoadmapTrack.infrastructure);
    expect(result.wasTie, isFalse);
  });

  test('the full onboarding list can be passed in unfiltered', () async {
    // It is the resuming case (issue #14): loadAnswers() returns everything.
    final result = await usecase([
      const OnboardingAnswer(
        stepKey: OnboardingKeys.experienceLevel,
        value: 'junior_developer',
      ),
      ..._quiz([RoadmapTrack.backend.slug, RoadmapTrack.backend.slug]),
      const OnboardingAnswer(
        stepKey: OnboardingKeys.goal,
        value: 'middle_level',
      ),
    ]);

    expect(result.track, RoadmapTrack.backend);
    expect(result.scores[RoadmapTrack.backend], 2);
  });
}
