// Tests of the tree of sequential topics (issue #13).
//
// What is verified is that the screen **respects** the sequencing that
// GetRoadmapTreeUseCase derived: the three distinguishable states and the
// locked ones not responding to a tap. The rule itself is already tested in
// test/domain/get_roadmap_tree_usecase_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/topic_node.dart';
import 'package:aspire_app/domain/entities/track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/roadmap_repository.dart';
import 'package:aspire_app/domain/usecases/get_roadmap_tree_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/roadmap_state.dart';
import 'package:aspire_app/presentation/widgets/organisms/roadmap_tree.dart';
import 'package:aspire_app/presentation/widgets/pages/roadmap_page.dart';

/// In-memory repository. It returns the **flat** list, as per the contract.
class FakeRoadmapRepository implements RoadmapRepository {
  FakeRoadmapRepository({this.topics = const [], this.failure});

  List<TopicNode> topics;
  AuthFailure? failure;
  int calls = 0;

  /// Topics marked as completed, in order, so a test can tell "it recorded it"
  /// from "it recorded it twice".
  final List<String> completed = <String>[];

  /// Failure for [markTopicCompleted] only: the challenges did load fine and
  /// only saving the progress fails (issue #47).
  AuthFailure? completionFailure;

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) async {
    calls++;
    if (failure != null) throw failure!;
    return topics.where((t) => t.trackId == track).toList();
  }

  @override
  Future<List<Track>> listTracks() async => const <Track>[];

  @override
  Future<void> markTopicCompleted(String topicId) async {
    if (completionFailure != null) throw completionFailure!;
    completed.add(topicId);
    // Mirrors the upsert: the row is one per topic, however many times it is
    // completed.
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
}) {
  return TopicNode(
    id: id,
    trackId: RoadmapTrack.frontend,
    parentId: parentId,
    title: id,
    sortOrder: sortOrder,
    isCompleted: isCompleted,
  );
}

/// The 5 placeholder topics that the migration of #7 seeds in frontend.
final _placeholders = [
  _node('Module A', sortOrder: 1),
  _node('Topic A1', parentId: 'Module A', sortOrder: 1, isCompleted: true),
  _node('Topic A2', parentId: 'Module A', sortOrder: 2),
  _node('Module B', sortOrder: 2),
  _node('Topic B1', parentId: 'Module B', sortOrder: 1),
];

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: RoadmapPage())),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeRoadmapRepository repo;

  setUp(() {
    repo = FakeRoadmapRepository();
    overrideDependency<RoadmapRepository>(repo);
    overrideDependency(GetRoadmapTreeUseCase(repo));

    resetRoadmap();
    currentProfile.value = const UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      track: RoadmapTrack.frontend,
    );
  });

  group('Tree display', () {
    testWidgets('it shows the hierarchy and the sort_order ordering',
        (tester) async {
      repo.topics = _placeholders;
      await _mount(tester);

      expect(find.text('Front-end'), findsOneWidget);
      for (final title in [
        'Module A',
        'Topic A1',
        'Topic A2',
        'Module B',
        'Topic B1',
      ]) {
        expect(find.text(title), findsOneWidget);
      }

      // The vertical order reflects sort_order: Module A before Module B.
      final yA = tester.getTopLeft(find.text('Module A')).dy;
      final yB = tester.getTopLeft(find.text('Module B')).dy;
      expect(yA, lessThan(yB));

      // And the children end up indented relative to their module.
      final xModule = tester.getTopLeft(find.text('Module A')).dx;
      final xChild = tester.getTopLeft(find.text('Topic A1')).dx;
      expect(xChild, greaterThan(xModule));
    });

    testWidgets('the three states are visually distinguishable',
        (tester) async {
      repo.topics = _placeholders;
      await _mount(tester);

      // Completed, available and locked, each with its label and its icon.
      // They are told apart by shape as well as by color.
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Available'), findsWidgets);
      expect(find.text('Locked'), findsWidgets);

      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.byIcon(Icons.play_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('there is a single available topic and the locked ones do not '
        'respond to a tap', (tester) async {
      repo.topics = _placeholders;
      final tapped = <String>[];

      await _mount(tester);

      // The organism is mounted on its own so the callback can be passed in.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoadmapTree(
                roots: roadmapTree.value,
                onTopicTap: (n) => tapped.add(n.id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A1 is completed, A2 is the available one, B1 is locked.
      await tester.tap(find.text('Topic B1'));
      await tester.pumpAndSettle();
      expect(tapped, isEmpty, reason: 'a locked one must not be actionable');

      await tester.tap(find.text('Topic A2'));
      await tester.pumpAndSettle();
      expect(tapped, ['Topic A2']);
    });
  });

  group('Progress percentage', () {
    testWidgets('it is computed over the completed leaves', (tester) async {
      repo.topics = _placeholders;
      await _mount(tester);

      // 3 leaves (A1, A2, B1), one completed → 33%.
      expect(roadmapLeaves.value, hasLength(3));
      expect(roadmapCompletedCount.value, 1);
      expect(find.textContaining('33% complete'), findsOneWidget);
      expect(find.textContaining('1 of 3 topics'), findsOneWidget);
    });

    testWidgets('with everything completed it reaches 100%', (tester) async {
      repo.topics = [
        _node('Module A', sortOrder: 1),
        _node('A1', parentId: 'Module A', sortOrder: 1, isCompleted: true),
        _node('A2', parentId: 'Module A', sortOrder: 2, isCompleted: true),
      ];
      await _mount(tester);

      expect(find.textContaining('100% complete'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
    });
  });

  group('Empty state', () {
    testWidgets('with no topics it shows neither a blank screen nor an error',
        (tester) async {
      // It is the real case today for backend and infrastructure.
      repo.topics = const [];
      await _mount(tester);

      expect(roadmapIsEmpty.value, isTrue);
      expect(find.byType(RoadmapEmptyState), findsOneWidget);
      expect(
        find.textContaining('Your Front-end path is being built'),
        findsOneWidget,
      );
      expect(find.byType(RoadmapErrorState), findsNothing);
      // And it does not show a 0% that would look like a failure.
      expect(find.textContaining('% complete'), findsNothing);
    });
  });

  group('Load error', () {
    testWidgets('it shows the translated message and allows retrying',
        (tester) async {
      repo.failure = const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'SocketException: Failed host lookup',
      );

      await _mount(tester);

      expect(find.byType(RoadmapErrorState), findsOneWidget);
      expect(find.textContaining("We couldn't connect"), findsOneWidget);
      // Nothing of the raw error in sight.
      expect(find.textContaining('SocketException'), findsNothing);

      // The retry asks for the data again; this time successfully.
      repo.failure = null;
      repo.topics = _placeholders;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repo.calls, 2);
      expect(find.byType(RoadmapErrorState), findsNothing);
      expect(find.text('Module A'), findsOneWidget);
    });
  });

  group('Without a track', () {
    testWidgets('a profile without a track does not break the screen',
        (tester) async {
      currentProfile.value = const UserProfile(
        id: 'u1',
        email: 'ana@example.com',
      );

      await _mount(tester);

      // The repository was not called and the empty state is shown.
      expect(repo.calls, 0);
      expect(find.byType(RoadmapEmptyState), findsOneWidget);
    });
  });
}
