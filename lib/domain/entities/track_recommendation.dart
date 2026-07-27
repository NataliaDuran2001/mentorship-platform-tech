// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// Output of `RecommendTrackUseCase`. It is a suggestion, not an assignment:
// issue #12 requires the user to confirm the result and be able to correct it
// by hand before it is persisted.

import 'roadmap_track.dart';

class TrackRecommendation {
  const TrackRecommendation({
    required this.track,
    required this.scores,
    required this.wasTie,
  });

  /// With no usable answers there is nothing to recommend.
  const TrackRecommendation.empty()
      : track = null,
        scores = const <RoadmapTrack, int>{
          RoadmapTrack.frontend: 0,
          RoadmapTrack.backend: 0,
          RoadmapTrack.infrastructure: 0,
        },
        wasTie = false;

  /// Suggested track, or `null` if there was no usable answer.
  final RoadmapTrack? track;

  /// Votes per track, including the ones that scored zero.
  final Map<RoadmapTrack, int> scores;

  /// The highest score was shared by two or more tracks and [track] came out
  /// of a tie-break. The UI should say so instead of presenting the result as
  /// conclusive.
  final bool wasTie;

  bool get hasRecommendation => track != null;
}
