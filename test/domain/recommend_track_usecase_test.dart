// Unit tests of the only real business logic of Module 1 (issue #8, AC3).
// They do not mount Flutter: the domain layer is pure Dart.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/usecases/recommend_track_usecase.dart';

/// Answers of the guided quiz, numbered from 1 as in issue #12.
List<OnboardingAnswer> _quiz(List<String> values) => [
      for (var i = 0; i < values.length; i++)
        OnboardingAnswer(
          stepKey: OnboardingKeys.quizQuestion(i + 1),
          value: values[i],
        ),
    ];

void main() {
  const usecase = RecommendTrackUseCase();

  group('every track can be recommended', () {
    for (final track in RoadmapTrack.values) {
      test('a majority of votes for ${track.slug} recommends ${track.slug}',
          () {
        // 2 votes for the track under test and 1 for a different one: a clear
        // majority.
        final other = RoadmapTrack.values.firstWhere((t) => t != track);
        final result = usecase(_quiz([track.slug, track.slug, other.slug]));

        expect(result.track, track);
        expect(result.wasTie, isFalse);
        expect(result.hasRecommendation, isTrue);
        expect(result.scores[track], 2);
        expect(result.scores[other], 1);
      });
    }
  });

  test('with no answers there is no recommendation', () {
    final result = usecase(const <OnboardingAnswer>[]);

    expect(result.hasRecommendation, isFalse);
    expect(result.track, isNull);
    expect(result.wasTie, isFalse);
    // The three tracks present at zero: the UI can paint the breakdown anyway.
    expect(result.scores.length, RoadmapTrack.values.length);
    expect(result.scores.values.every((v) => v == 0), isTrue);
  });

  test('answers that do not map to a track do not count as votes', () {
    // Level, goal and "I'm not sure yet": none of them is a track.
    final result = usecase(const [
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

  test('a three-way tie: frontend wins and it is flagged as a tie', () {
    final result = usecase(_quiz([
      RoadmapTrack.backend.slug,
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.frontend.slug,
    ]));

    expect(result.wasTie, isTrue);
    expect(result.track, RoadmapTrack.frontend);
  });

  test('a tie without frontend: backend wins by declaration order', () {
    final result = usecase(_quiz([
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.backend.slug,
    ]));

    expect(result.wasTie, isTrue);
    expect(result.track, RoadmapTrack.backend);
  });

  test('the tie-break is deterministic: arrival order does not change it', () {
    final a = usecase(_quiz([
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.backend.slug,
    ]));
    final b = usecase(_quiz([
      RoadmapTrack.backend.slug,
      RoadmapTrack.infrastructure.slug,
    ]));

    expect(a.track, b.track);
  });

  test('a single answer is enough and is not a tie', () {
    final result = usecase(_quiz([RoadmapTrack.infrastructure.slug]));

    expect(result.track, RoadmapTrack.infrastructure);
    expect(result.wasTie, isFalse);
  });

  test('the full onboarding list can be passed in unfiltered', () {
    // It is the resuming case (issue #14): loadAnswers() returns everything.
    final result = usecase([
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
