// Data layer: Model that parses a topic from the `topics` table and maps to
// the TopicNode entity of the Domain layer.
//
// The model does NOT build the hierarchy nor decide the sequential status: it
// returns the flat node with `isCompleted` resolved. Nesting by `parentId`,
// sorting by `sortOrder` and deriving `TopicStatus` belong to
// GetRoadmapTreeUseCase, because they are business rules and not parsing
// details.

import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/topic_node.dart';

class TopicModel {
  const TopicModel({
    required this.id,
    required this.trackId,
    required this.title,
    required this.sortOrder,
    this.parentId,
    this.description,
  });

  /// Columns of the `select`. Explicit and not `*`: adding a column to the
  /// table must not silently change what travels to the client.
  static const String columns =
      'id, track_id, parent_id, title, description, sort_order';

  final String id;
  final String trackId;
  final String? parentId;
  final String title;
  final String? description;
  final int sortOrder;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      trackId: json['track_id'] as String,
      parentId: json['parent_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts to entity. [isCompleted] comes from `user_progress`, not from
  /// this table: the topic is the same for everyone, the progress belongs to
  /// each user.
  ///
  /// A `track_id` the enum does not know is discarded by returning `null`: it
  /// is safer not to show a topic the app does not understand than to invent a
  /// track for it.
  TopicNode? toEntity({bool isCompleted = false}) {
    final track = RoadmapTrack.fromSlug(trackId);
    if (track == null) return null;

    return TopicNode(
      id: id,
      trackId: track,
      parentId: parentId,
      title: title,
      description: description,
      sortOrder: sortOrder,
      isCompleted: isCompleted,
    );
  }
}
