// Tests of how a finished lab is graded: the two kinds of step and how each
// is earned, the tier each result lands in, and the reading that must never
// be confused —a perfect run, and a lab that had nothing at stake.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/lab_score.dart';

void main() {
  group('the steps of a lesson', () {
    test('counts explanations and exercises alike in the total', () {
      // What the learner lived: three screens.
      const score = LabScore(
        exercisesCorrect: 2,
        exercisesTotal: 2,
        concepts: 1,
      );

      expect(score.totalSteps, 3);
      expect(score.completedSteps, 3);
    });

    test('an explanation is earned by reading it', () {
      // Both exercises retried, the explanation still counts.
      const score = LabScore(
        exercisesCorrect: 0,
        exercisesTotal: 2,
        concepts: 1,
      );

      expect(score.completedSteps, 1);
      expect(score.totalSteps, 3);
      expect(score.missed, 2);
    });

    test('a lab with no steps at all is empty', () {
      const score = LabScore.empty();

      expect(score.totalSteps, 0);
      expect(score.completedSteps, 0);
      expect(score.hasExercises, isFalse);
    });

    test('a section that only explains has nothing at stake', () {
      const score = LabScore(concepts: 3);

      expect(score.totalSteps, 3);
      expect(score.completedSteps, 3);
      // Every step earned, but nothing could have been got wrong.
      expect(score.hasExercises, isFalse);
    });
  });

  group('accuracy', () {
    test('is the share of the lesson steps that went well', () {
      expect(
        const LabScore(
          exercisesCorrect: 3,
          exercisesTotal: 4,
          concepts: 1,
        ).accuracy,
        0.8,
      );
    });

    test('rounds to a whole percentage for display', () {
      expect(
        const LabScore(
          exercisesCorrect: 0,
          exercisesTotal: 2,
          concepts: 1,
        ).percentage,
        33,
      );
    });

    test('is zero rather than a division by zero on an empty lab', () {
      expect(const LabScore.empty().accuracy, 0.0);
      expect(const LabScore.empty().percentage, 0);
    });
  });

  group('bands', () {
    test('every step earned is a perfect run', () {
      expect(
        const LabScore(
          exercisesCorrect: 2,
          exercisesTotal: 2,
          concepts: 1,
        ).band,
        LabScoreBand.perfect,
      );
    });

    test('theory can never hand out a perfect run', () {
      // Reading three explanations does not make up for a retried exercise:
      // as long as one exercise was missed, a step is missing.
      const score = LabScore(
        exercisesCorrect: 1,
        exercisesTotal: 2,
        concepts: 3,
      );

      expect(score.completedSteps, 4);
      expect(score.totalSteps, 5);
      expect(score.band, isNot(LabScoreBand.perfect));
    });

    test('one slip on a long section still reads as strong', () {
      expect(
        const LabScore(
          exercisesCorrect: 3,
          exercisesTotal: 4,
          concepts: 1,
        ).band,
        LabScoreBand.strong,
      );
    });

    test('half or better, but not strong, is getting there', () {
      expect(
        const LabScore(
          exercisesCorrect: 1,
          exercisesTotal: 3,
          concepts: 1,
        ).band,
        LabScoreBand.gettingThere,
      );
    });

    test('below half is worth a replay', () {
      expect(
        const LabScore(
          exercisesCorrect: 0,
          exercisesTotal: 4,
          concepts: 1,
        ).band,
        LabScoreBand.needsReview,
      );
    });

    test('missing every exercise no longer reads as a total defeat', () {
      // The learner read the explanation and pushed through both exercises.
      // The number says 1 of 3, not 0 of 2: the reading was real progress.
      const score = LabScore(
        exercisesCorrect: 0,
        exercisesTotal: 2,
        concepts: 1,
      );

      expect(score.completedSteps, 1);
      expect(score.band, LabScoreBand.needsReview);
    });
  });
}
