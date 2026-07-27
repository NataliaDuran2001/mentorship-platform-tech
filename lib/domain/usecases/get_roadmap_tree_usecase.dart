// Domain layer: Use case encapsulating one business rule of the app.
//
// It builds the topic tree of a track from the flat list the repository
// delivers, and derives the sequencing from it.
//
// The hierarchy and the "what is unlocked" are business rules, not
// presentation details: if they lived in the widget of issue #13 they could
// not be tested without booting Flutter, and every new screen could interpret
// them differently.

import '../entities/roadmap_track.dart';
import '../entities/topic_node.dart';
import '../repositories/roadmap_repository.dart';

class GetRoadmapTreeUseCase {
  const GetRoadmapTreeUseCase(this.repository);

  final RoadmapRepository repository;

  /// Top-level topics of the track, with their nested children, sorted and
  /// with the sequential status already resolved.
  Future<List<TopicNode>> call(RoadmapTrack track) async {
    final flat = await repository.listTopics(track);
    return buildTree(flat);
  }

  /// Turns the flat list into a tree and derives the status of each node.
  ///
  /// Exposed apart from [call] so the rule can be tested without a
  /// repository.
  List<TopicNode> buildTree(List<TopicNode> flat) {
    final byParent = <String?, List<TopicNode>>{};
    final knownIds = flat.map((node) => node.id).toSet();

    for (final node in flat) {
      // A `parentId` that is not in the list is treated as a root: we prefer
      // showing the orphan topic over making it disappear silently.
      final parent =
          knownIds.contains(node.parentId) ? node.parentId : null;
      byParent.putIfAbsent(parent, () => <TopicNode>[]).add(node);
    }

    List<TopicNode> childrenOf(String? parentId) {
      final siblings = byParent[parentId] ?? const <TopicNode>[];
      final ordered = [...siblings]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return [
        for (final node in ordered)
          node.copyWith(children: childrenOf(node.id)),
      ];
    }

    return _deriveStatus(childrenOf(null));
  }

  /// Marks the first uncompleted leaf topic as [TopicStatus.available] and
  /// every following one as [TopicStatus.locked]. A node with children
  /// inherits: it is completed if all of its children are, available if any
  /// of them is, and locked in any other case.
  List<TopicNode> _deriveStatus(List<TopicNode> roots) {
    var availableTaken = false;

    TopicNode visit(TopicNode node) {
      if (node.isLeaf) {
        if (node.isCompleted) {
          return node.copyWith(status: TopicStatus.completed);
        }
        if (!availableTaken) {
          availableTaken = true;
          return node.copyWith(status: TopicStatus.available);
        }
        return node.copyWith(status: TopicStatus.locked);
      }

      final children = [for (final child in node.children) visit(child)];

      final TopicStatus status;
      if (children.every((c) => c.status == TopicStatus.completed)) {
        status = TopicStatus.completed;
      } else if (children.any((c) => c.status == TopicStatus.available)) {
        status = TopicStatus.available;
      } else {
        status = TopicStatus.locked;
      }

      return node.copyWith(children: children, status: status);
    }

    return [for (final root in roots) visit(root)];
  }
}
