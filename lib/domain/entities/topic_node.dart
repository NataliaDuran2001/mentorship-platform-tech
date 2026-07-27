// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// Node of a roadmap's topic tree. The hierarchy is built from
// [TopicNode.parentId] and the order among siblings from
// [TopicNode.sortOrder].

import 'roadmap_track.dart';

/// Sequential status of a topic.
///
/// It is what makes the path deterministic instead of a free menu: there is
/// only one [available] topic at a time and [locked] ones do not react to tap.
enum TopicStatus {
  /// Already completed by the user.
  completed,

  /// The next uncompleted one. It is the only actionable one.
  available,

  /// Not reachable yet: there are earlier uncompleted topics.
  locked,
}

class TopicNode {
  const TopicNode({
    required this.id,
    required this.trackId,
    required this.title,
    required this.sortOrder,
    this.parentId,
    this.description,
    this.isCompleted = false,
    this.children = const <TopicNode>[],
    this.status = TopicStatus.locked,
  });

  final String id;
  final RoadmapTrack trackId;

  /// Parent node, or `null` if it is a top-level topic.
  final String? parentId;

  final String title;
  final String? description;

  /// Order among siblings. It is not unique across the whole tree, only
  /// within the parent.
  final int sortOrder;

  /// Raw fact coming from `user_progress`: the user completed the topic.
  final bool isCompleted;

  /// Children already sorted by [sortOrder]. Empty in leaf nodes and also
  /// while the tree has not been built (the Data layer delivers a flat list).
  final List<TopicNode> children;

  /// Status derived by `GetRoadmapTreeUseCase` when building the tree.
  ///
  /// The default value is [TopicStatus.locked] on purpose: a node nobody
  /// evaluated must not look actionable.
  final TopicStatus status;

  bool get isLeaf => children.isEmpty;

  /// This node and all its descendants, in traversal order.
  Iterable<TopicNode> get flattened =>
      [this, for (final child in children) ...child.flattened];

  TopicNode copyWith({
    List<TopicNode>? children,
    TopicStatus? status,
    bool? isCompleted,
  }) {
    return TopicNode(
      id: id,
      trackId: trackId,
      parentId: parentId,
      title: title,
      description: description,
      sortOrder: sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      children: children ?? this.children,
      status: status ?? this.status,
    );
  }
}
