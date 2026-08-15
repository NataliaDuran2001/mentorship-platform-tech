// Tests of the accounting behind the score of a lab: only the FIRST check of
// each challenge counts, retries move the lab forward without rewriting it,
// and explanations stay out of the denominator.
//
// It exercises the state layer and not a widget: what is at stake is what gets
// written down and when, which needs no painting.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/lab_challenge.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/topic_node.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
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

class _FakeLabRepository implements LabRepository {
  _FakeLabRepository(this.byTopic);

  final Map<String, List<LabChallenge>> byTopic;

  @override
  Future<List<LabChallenge>> getChallengesForTopic(String topicId) async =>
      byTopic[topicId] ?? const <LabChallenge>[];
}

MultipleChoiceChallenge _challenge(String id, String question) {
  return MultipleChoiceChallenge(
    id: id,
    topicId: 't1',
    question: question,
    options: const {'a': 'Right', 'b': 'Wrong'},
    correctOptionId: 'a',
  );
}

TheoryChallenge _theory(String id, String question) {
  return TheoryChallenge(
    id: id,
    topicId: 't1',
    question: question,
    blocks: const [
      TheoryBlock(type: TheoryBlockType.paragraph, text: 'Open, write, close.'),
    ],
  );
}

/// Answers the current challenge right on the first go and moves on.
Future<void> _solveFirstTry() async {
  setLabAnswer('selected', 'a');
  submitLabAnswer();
  await nextLabChallenge();
}

/// Gets the current challenge wrong once, then right, and moves on. This is
/// the path the lab actually forces: there is no way past without the answer.
Future<void> _solveAfterRetry() async {
  setLabAnswer('selected', 'b');
  submitLabAnswer();
  expect(labIsCurrentValid.value, isFalse);

  setLabAnswer('selected', 'a');
  submitLabAnswer();
  expect(labIsCurrentValid.value, isTrue);

  await nextLabChallenge();
}

void main() {
  setUp(() async {
    final roadmapRepo = FakeRoadmapRepository(
      topics: const [
        TopicNode(
          id: 't1',
          trackId: RoadmapTrack.frontend,
          title: 't1',
          sortOrder: 1,
        ),
      ],
    );
    overrideDependency<RoadmapRepository>(roadmapRepo);
    overrideDependency(GetRoadmapTreeUseCase(roadmapRepo));
    overrideDependency(CompleteTopicUseCase(roadmapRepo));
    overrideDependency<LabRepository>(
      _FakeLabRepository({
        // The shape the path is built on: an explanation, then the practice
        // that exercises it.
        't1': [
          _theory('c1', 'What HTML is for'),
          _challenge('c2', 'Which language owns color?'),
          _challenge('c3', 'Which tag closes a paragraph?'),
        ],
        // A section that only explains, and grades nothing.
        't-theory': [_theory('c1', 'A'), _theory('c2', 'B')],
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

  test('a clean run scores every gradable challenge', () async {
    await loadLabs('t1');
    await nextLabChallenge(); // the explanation
    await _solveFirstTry();
    await _solveFirstTry();

    final score = labScore.value;
    expect(score.correct, 2);
    expect(score.total, 2);
    expect(labMissedQuestions.value, isEmpty);
  });

  test('explanations are not counted in the denominator', () async {
    await loadLabs('t1');
    await nextLabChallenge();
    await _solveFirstTry();
    await _solveFirstTry();

    // Three challenges were played, but only two could be got wrong.
    expect(labChallenges.value.length, 3);
    expect(labScore.value.total, 2);
  });

  test('getting it right after a retry does not count as first try', () async {
    await loadLabs('t1');
    await nextLabChallenge();
    await _solveAfterRetry();
    await _solveFirstTry();

    final score = labScore.value;
    expect(score.correct, 1);
    expect(score.total, 2);
    expect(score.missed, 1);
  });

  test('the retried challenge is named so it can be reviewed', () async {
    await loadLabs('t1');
    await nextLabChallenge();
    await _solveFirstTry();
    await _solveAfterRetry();

    expect(labMissedQuestions.value, ['Which tag closes a paragraph?']);
  });

  test('checking the same challenge again never revises its outcome', () async {
    await loadLabs('t1');
    await nextLabChallenge();

    setLabAnswer('selected', 'b');
    submitLabAnswer();
    expect(labFirstTryCorrectIndices.value, isEmpty);

    // Three more goes at the same challenge, the last one right. The first
    // check is the one on record, and it stays that way.
    setLabAnswer('selected', 'b');
    submitLabAnswer();
    setLabAnswer('selected', 'a');
    submitLabAnswer();
    setLabAnswer('selected', 'a');
    submitLabAnswer();

    expect(labFirstTryCorrectIndices.value, isEmpty);
    expect(labCheckedIndices.value, {1});
  });

  test('a section that only explains has nothing to score', () async {
    await loadLabs('t-theory');
    await nextLabChallenge();
    await nextLabChallenge();

    expect(labIsCompleted.value, isTrue);
    expect(labScore.value.isScored, isFalse);
    expect(labMissedQuestions.value, isEmpty);
  });

  test('replaying a lab starts the score from scratch', () async {
    await loadLabs('t1');
    await nextLabChallenge();
    await _solveAfterRetry();
    await _solveFirstTry();
    expect(labScore.value.correct, 1);

    // Same lab again. A previous bad run must not follow the learner around.
    await loadLabs('t1');
    expect(labScore.value.correct, 0);
    expect(labCheckedIndices.value, isEmpty);
    expect(labMissedQuestions.value, isEmpty);

    await nextLabChallenge();
    await _solveFirstTry();
    await _solveFirstTry();

    expect(labScore.value.correct, 2);
    expect(labScore.value.total, 2);
  });
}
