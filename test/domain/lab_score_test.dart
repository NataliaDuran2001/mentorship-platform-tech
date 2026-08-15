// Tests of how a finished lab is graded: the tier each accuracy lands in, and
// the two readings that must never be confused —a perfect run, and a lab that
// had nothing to grade in the first place.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/lab_score.dart';

void main() {
  group('what there is to score', () {
    test('a lab with no gradable challenges is not scored', () {
      const score = LabScore.empty();

      expect(score.isScored, isFalse);
      expect(score.accuracy, 0.0);
      // Nothing was got wrong, because nothing was ever asked.
      expect(score.missed, 0);
    });

    test('a lab with gradable challenges is scored', () {
      const score = LabScore(correct: 0, total: 3);

      expect(score.isScored, isTrue);
      expect(score.missed, 3);
    });
  });

  group('accuracy', () {
    test('is the share answered right on the first try', () {
      expect(const LabScore(correct: 4, total: 5).accuracy, 0.8);
      expect(const LabScore(correct: 1, total: 4).accuracy, 0.25);
    });

    test('rounds to a whole percentage for display', () {
      expect(const LabScore(correct: 2, total: 3).percentage, 67);
      expect(const LabScore(correct: 1, total: 3).percentage, 33);
    });

    test('is zero rather than a division by zero when nothing is scored', () {
      expect(const LabScore.empty().accuracy, 0.0);
      expect(const LabScore.empty().percentage, 0);
    });
  });

  group('bands', () {
    test('every scored challenge right on the first try is perfect', () {
      expect(const LabScore(correct: 5, total: 5).band, LabScoreBand.perfect);
      // Perfect is about missing none, not about being a long section.
      expect(const LabScore(correct: 2, total: 2).band, LabScoreBand.perfect);
    });

    test('one slip on a long section still reads as strong', () {
      expect(const LabScore(correct: 4, total: 5).band, LabScoreBand.strong);
    });

    test('half or better, but not strong, is getting there', () {
      expect(
        const LabScore(correct: 3, total: 5).band,
        LabScoreBand.gettingThere,
      );
      // Exactly on the threshold.
      expect(
        const LabScore(correct: 1, total: 2).band,
        LabScoreBand.gettingThere,
      );
    });

    test('below half is worth a replay', () {
      expect(
        const LabScore(correct: 2, total: 5).band,
        LabScoreBand.needsReview,
      );
      expect(
        const LabScore(correct: 0, total: 3).band,
        LabScoreBand.needsReview,
      );
    });

    test('a short section cannot round its way into a perfect run', () {
      // 1 of 2 is 50%: half the section was retried. Whatever else it is, it
      // is not the clean run that `perfect` congratulates.
      const half = LabScore(correct: 1, total: 2);

      expect(half.band, isNot(LabScoreBand.perfect));
      expect(half.band, isNot(LabScoreBand.strong));
    });
  });
}
