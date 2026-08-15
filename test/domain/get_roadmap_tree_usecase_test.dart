// Unit tests of the tree building and of sequencing (issue #8). The rule they
// verify is the one that holds up AC 1.3: the path is deterministic, with a
// single actionable topic at a time.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/lab_score.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/topic_node.dart';
import 'package:aspire_app/domain/entities/track.dart';
import 'package:aspire_app/domain/repositories/roadmap_repository.dart';
import 'package:aspire_app/domain/usecases/get_roadmap_tree_usecase.dart';

/// In-memory repository: enough to test the rule without touching Supabase.
class _FakeRoadmapRepository implements RoadmapRepository {
  _FakeRoadmapRepository(this.topics);

  List<TopicNode> topics;

  @override
  Future<List<Track>> listTracks() async => const <Track>[];

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) async =>
      topics.where((t) => t.trackId == track).toList();

  @override
  Future<void> markTopicCompleted(String topicId, {LabScore? score}) async {
    topics = [
      for (final topic in topics)
        topic.id == topicId ? topic.copyWith(isCompleted: true) : topic,
    ];
  }
}

TopicNode _node(
  String id, {
  String? parentId,
  int sortOrder = 0,
  bool isCompleted = false,
  RoadmapTrack track = RoadmapTrack.frontend,
}) {
  return TopicNode(
    id: id,
    trackId: track,
    parentId: parentId,
    title: id,
    sortOrder: sortOrder,
    isCompleted: isCompleted,
  );
}

void main() {
  const usecase = GetRoadmapTreeUseCase(_NoRepo());

  group('tree building', () {
    test('nests by parentId and sorts siblings by sortOrder', () {
      final tree = usecase.buildTree([
        _node('b', sortOrder: 2),
        _node('a', sortOrder: 1),
        _node('a2', parentId: 'a', sortOrder: 2),
        _node('a1', parentId: 'a', sortOrder: 1),
      ]);

      expect(tree.map((n) => n.id), ['a', 'b']);
      expect(tree.first.children.map((n) => n.id), ['a1', 'a2']);
      expect(tree.last.isLeaf, isTrue);
    });

    test('a nonexistent parentId is treated as a root, not discarded', () {
      final tree = usecase.buildTree([
        _node('a', sortOrder: 1),
        _node('orphan', parentId: 'does-not-exist', sortOrder: 2),
      ]);

      expect(tree.map((n) => n.id), ['a', 'orphan']);
    });

    test('an empty list gives an empty tree', () {
      expect(usecase.buildTree(const []), isEmpty);
    });

    test('flattened walks the node and all of its descendants', () {
      final tree = usecase.buildTree([
        _node('a', sortOrder: 1),
        _node('a1', parentId: 'a', sortOrder: 1),
        _node('a1x', parentId: 'a1', sortOrder: 1),
      ]);

      expect(tree.first.flattened.map((n) => n.id), ['a', 'a1', 'a1x']);
    });
  });

  group('sequencing', () {
    test('only the first uncompleted topic is available', () {
      final tree = usecase.buildTree([
        _node('t1', sortOrder: 1, isCompleted: true),
        _node('t2', sortOrder: 2),
        _node('t3', sortOrder: 3),
      ]);

      expect(tree.map((n) => n.status), [
        TopicStatus.completed,
        TopicStatus.available,
        TopicStatus.locked,
      ]);
    });

    test('with nothing completed the first one is the available one', () {
      final tree = usecase.buildTree([
        _node('t1', sortOrder: 1),
        _node('t2', sortOrder: 2),
      ]);

      expect(tree.first.status, TopicStatus.available);
      expect(tree.last.status, TopicStatus.locked);
    });

    test('the order that rules is sortOrder, not the list order', () {
      final tree = usecase.buildTree([
        _node('second', sortOrder: 2),
        _node('first', sortOrder: 1),
      ]);

      expect(tree.first.id, 'first');
      expect(tree.first.status, TopicStatus.available);
    });

    test('there is exactly one available topic in the whole tree', () {
      final tree = usecase.buildTree([
        _node('a', sortOrder: 1),
        _node('a1', parentId: 'a', sortOrder: 1, isCompleted: true),
        _node('a2', parentId: 'a', sortOrder: 2),
        _node('b', sortOrder: 2),
        _node('b1', parentId: 'b', sortOrder: 1),
      ]);

      final leaves = tree
          .expand((n) => n.flattened)
          .where((n) => n.isLeaf)
          .toList();
      final available = leaves
          .where((n) => n.status == TopicStatus.available)
          .toList();

      expect(available.map((n) => n.id), ['a2']);
    });

    test('a node with children inherits the status of its descendants', () {
      final tree = usecase.buildTree([
        _node('a', sortOrder: 1),
        _node('a1', parentId: 'a', sortOrder: 1, isCompleted: true),
        _node('b', sortOrder: 2),
        _node('b1', parentId: 'b', sortOrder: 1),
        _node('c', sortOrder: 3),
        _node('c1', parentId: 'c', sortOrder: 1),
      ]);

      // 'a' complete, 'b' holds the available one, 'c' stays locked.
      expect(tree.map((n) => n.status), [
        TopicStatus.completed,
        TopicStatus.available,
        TopicStatus.locked,
      ]);
    });
  });

  test(
    'call filters by track and returns the tree of the requested track',
    () async {
      final repo = _FakeRoadmapRepository([
        _node('fe1', sortOrder: 1),
        _node('be1', sortOrder: 1, track: RoadmapTrack.backend),
      ]);

      final tree = await GetRoadmapTreeUseCase(repo)(RoadmapTrack.backend);

      expect(tree.map((n) => n.id), ['be1']);
      expect(tree.first.status, TopicStatus.available);
    },
  );
}

/// Unusable repository, for the tests that only exercise `buildTree`.
class _NoRepo implements RoadmapRepository {
  const _NoRepo();

  @override
  Future<List<Track>> listTracks() => throw UnimplementedError();

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) =>
      throw UnimplementedError();

  @override
  Future<void> markTopicCompleted(String topicId, {LabScore? score}) =>
      throw UnimplementedError();
}
