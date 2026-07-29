// Tests of the loop that closes the path (issue #47): solving the last
// challenge of a lab completes the topic, the tree is refreshed and the next
// topic stops being locked.
//
// It exercises the state layer and not a widget: what is at stake is the
// sequence of calls —use case, then reload— and the recovery when recording
// the progress fails, none of which needs to be painted.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/lab_challenge.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/topic_node.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/lab_repository.dart';
import 'package:aspire_app/domain/repositories/roadmap_repository.dart';
import 'package:aspire_app/domain/usecases/complete_topic_usecase.dart';
import 'package:aspire_app/domain/usecases/get_roadmap_tree_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/lab_actions.dart';
import 'package:aspire_app/presentation/state/lab_state.dart';
import 'package:aspire_app/presentation/state/roadmap_actions.dart';
import 'package:aspire_app/presentation/state/roadmap_state.dart';

import 'roadmap_test.dart' show FakeRoadmapRepository;

/// In-memory catalogue of challenges, keyed by topic.
class _FakeLabRepository implements LabRepository {
  _FakeLabRepository(this.byTopic);

  final Map<String, List<LabChallenge>> byTopic;

  @override
  Future<List<LabChallenge>> getChallengesForTopic(String topicId) async =>
      byTopic[topicId] ?? const <LabChallenge>[];
}

MultipleChoiceChallenge _challenge(String id, String topicId) {
  return MultipleChoiceChallenge(
    id: id,
    topicId: topicId,
    question: 'What closes a topic?',
    options: const {'a': 'Solving every challenge', 'b': 'Nothing'},
    correctOptionId: 'a',
  );
}

TopicNode _topic(String id, int sortOrder) {
  return TopicNode(
    id: id,
    trackId: RoadmapTrack.frontend,
    title: id,
    sortOrder: sortOrder,
  );
}

/// Solves the current challenge with the right answer and moves on.
Future<void> _solveCurrent() async {
  setLabAnswer('selected', 'a');
  submitLabAnswer();
  expect(labIsCurrentValid.value, isTrue);
  await nextLabChallenge();
}

void main() {
  late FakeRoadmapRepository roadmapRepo;

  setUp(() async {
    roadmapRepo = FakeRoadmapRepository(
      topics: [_topic('t1', 1), _topic('t2', 2)],
    );
    overrideDependency<RoadmapRepository>(roadmapRepo);
    overrideDependency(GetRoadmapTreeUseCase(roadmapRepo));
    overrideDependency(CompleteTopicUseCase(roadmapRepo));
    overrideDependency<LabRepository>(
      _FakeLabRepository({
        't1': [_challenge('c1', 't1'), _challenge('c2', 't1')],
      }),
    );

    resetRoadmap();
    currentProfile.value = const UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      track: RoadmapTrack.frontend,
    );
    await loadRoadmap();
  });

  test('the tree starts with the first topic available and the second locked',
      () {
    expect(roadmapTree.value[0].status, TopicStatus.available);
    expect(roadmapTree.value[1].status, TopicStatus.locked);
    expect(roadmapProgress.value, 0.0);
  });

  test('an intermediate challenge does not close the topic', () async {
    await loadLabs('t1');
    await _solveCurrent();

    expect(labIsCompleted.value, isFalse);
    expect(roadmapRepo.completed, isEmpty);
  });

  test('solving the last challenge records the topic and unlocks the next one',
      () async {
    await loadLabs('t1');
    await _solveCurrent();
    await _solveCurrent();

    expect(labIsCompleted.value, isTrue);
    expect(labSaveError.value, isNull);
    expect(labSavingProgress.value, isFalse);

    // Recorded once, and against the topic the lab was opened with.
    expect(roadmapRepo.completed, ['t1']);

    // And the path is already refreshed: the progress is visible without
    // anyone reloading the screen by hand.
    expect(roadmapTree.value[0].status, TopicStatus.completed);
    expect(roadmapTree.value[1].status, TopicStatus.available);
    expect(roadmapCompletedCount.value, 1);
    expect(roadmapProgress.value, 0.5);
  });

  test('replaying a finished lab keeps a single completed topic', () async {
    await loadLabs('t1');
    await _solveCurrent();
    await _solveCurrent();

    // Same lab again, from the start: this is what a user does when they want
    // to practise, and it must not undo nor duplicate anything.
    await loadLabs('t1');
    await _solveCurrent();
    await _solveCurrent();

    expect(labSaveError.value, isNull);
    expect(roadmapCompletedCount.value, 1);
    expect(roadmapTree.value[0].status, TopicStatus.completed);
    expect(roadmapTree.value[1].status, TopicStatus.available);
  });

  test('a failure recording the progress is reported and can be retried',
      () async {
    roadmapRepo.completionFailure =
        const AuthFailure(AuthFailureKind.network);

    await loadLabs('t1');
    await _solveCurrent();
    await _solveCurrent();

    // The lab is finished —the answers were right— but the topic did not
    // close: it is reported instead of being silently swallowed.
    expect(labIsCompleted.value, isTrue);
    expect(labSaveError.value, isNotNull);
    expect(labError.value, isNull);
    expect(roadmapTree.value[0].status, TopicStatus.available);

    roadmapRepo.completionFailure = null;
    await completeCurrentTopic();

    expect(labSaveError.value, isNull);
    expect(roadmapRepo.completed, ['t1']);
    expect(roadmapTree.value[0].status, TopicStatus.completed);
  });

  test('a lab with no challenges completes nothing', () async {
    await loadLabs('t-empty');

    expect(labChallenges.value, isEmpty);
    expect(labIsCompleted.value, isFalse);
    expect(roadmapRepo.completed, isEmpty);
  });
}
