// Domain layer: Use case encapsulating one business rule of the app.
//
// It translates the guided quiz answers into a recommended track. It is the
// only real business logic of Module 1, and that is why it lives here and not
// in a widget: issue #12 explicitly requires the decision not to be made in
// the UI.

import '../entities/onboarding_answer.dart';
import '../entities/roadmap_track.dart';
import '../entities/track_recommendation.dart';

class RecommendTrackUseCase {
  const RecommendTrackUseCase();

  /// Counts one vote for every answer whose value maps to a track and returns
  /// the most voted one.
  ///
  /// It accepts the full list of onboarding answers, not just the quiz ones:
  /// those that do not map to a track (`student`, `first_job`, `unknown`)
  /// simply do not vote. That makes it possible to pass it whatever
  /// `OnboardingRepository.loadAnswers()` returns when resuming (issue #14)
  /// without filtering anything first.
  ///
  /// Ties: the declaration order of [RoadmapTrack] wins —frontend, backend,
  /// infrastructure— and the result comes marked with `wasTie: true`. The
  /// criterion is arbitrary on purpose; what matters is that it is
  /// **deterministic** and that the tie can be shown, because issue #12
  /// requires the user to confirm the recommendation and be able to correct
  /// it by hand. Frontend comes first for being the most common entry point
  /// for someone just starting out, which is the product's dominant profile.
  TrackRecommendation call(List<OnboardingAnswer> answers) {
    final scores = <RoadmapTrack, int>{
      for (final track in RoadmapTrack.values) track: 0,
    };

    var votes = 0;
    for (final answer in answers) {
      final track = RoadmapTrack.fromSlug(answer.value);
      if (track == null) continue;
      scores[track] = scores[track]! + 1;
      votes++;
    }

    if (votes == 0) return const TrackRecommendation.empty();

    final highest = scores.values.reduce((a, b) => a > b ? a : b);
    final winners = RoadmapTrack.values
        .where((track) => scores[track] == highest)
        .toList(growable: false);

    return TrackRecommendation(
      track: winners.first,
      scores: scores,
      wasTie: winners.length > 1,
    );
  }
}
