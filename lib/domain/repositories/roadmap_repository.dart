// Domain layer: Contract (interface) of the roadmap repository.
// It defines WHAT can be done, not HOW. The implementation lives in `data`.

import '../entities/roadmap_track.dart';
import '../entities/topic_node.dart';
import '../entities/track.dart';

abstract class RoadmapRepository {
  /// The 3 tracks with their editorial content, as seeded in the `tracks`
  /// table.
  Future<List<Track>> listTracks();

  /// Topics of a track as a **flat list**, with `isCompleted` already
  /// resolved against the user's progress.
  ///
  /// It returns the flat list and not the built tree on purpose: the
  /// hierarchy and the sequencing are business rules, so they are derived by
  /// `GetRoadmapTreeUseCase` and not by the Data layer or a widget.
  Future<List<TopicNode>> listTopics(RoadmapTrack track);
}
