// Domain layer: How well a lab was solved, and the plain-language tier that
// reading lands in.
//
// The score counts a challenge as correct only when it was answered right on
// the FIRST check. Retrying until it is right is still how the lab advances —
// nobody closes a topic without arriving at the answer — so a plain
// "challenges solved" count would be N of N for everyone and would mean
// nothing. First-try accuracy is the only reading of this flow that carries
// information.
//
// Explanations are not scored and do not count towards [total]: there is
// nothing to get wrong on a screen whose whole interaction is acknowledging
// it. A section made only of explanations therefore has no score at all,
// which is what [isScored] is for.

/// The plain-language tier a [LabScore] falls into.
///
/// It decides which message closes the lab, so the thresholds are a product
/// rule and live here rather than next to the colors that render them.
enum LabScoreBand {
  /// Every scored challenge right on the first try.
  perfect,

  /// At least [LabScore.strongThreshold] — one slip on a long section.
  strong,

  /// At least [LabScore.gettingThereThreshold] — got there, with effort.
  gettingThere,

  /// Below half. The section is worth replaying before moving on.
  needsReview,
}

class LabScore {
  const LabScore({
    required this.correct,
    required this.total,
    this.concepts = 0,
  });

  /// A lab with nothing to score, e.g. one made entirely of explanations.
  const LabScore.empty() : correct = 0, total = 0, concepts = 0;

  /// Answered right on the first check.
  final int correct;

  /// Challenges that could be got wrong. Explanations are excluded.
  final int total;

  /// Explanations read on the way through.
  ///
  /// They are not scored, but they are counted: a learner who walked through
  /// five screens and is shown "0 / 2" has no way to tell whether the number
  /// is wrong or the explanations simply do not count. Saying how many were
  /// read is what closes that gap.
  final int concepts;

  /// Accuracy at or above which a run reads as [LabScoreBand.strong].
  static const double strongThreshold = 0.8;

  /// Accuracy at or above which a run reads as [LabScoreBand.gettingThere].
  static const double gettingThereThreshold = 0.5;

  /// False when there was nothing to score, and the screen should show no
  /// number at all rather than a misleading `0 / 0`.
  bool get isScored => total > 0;

  /// Share of scored challenges answered right on the first try, 0.0 to 1.0.
  /// Zero when there is nothing to score.
  double get accuracy => isScored ? correct / total : 0.0;

  /// [accuracy] as a whole percentage, for display.
  int get percentage => (accuracy * 100).round();

  /// How many were not answered right on the first try.
  int get missed => total - correct;

  LabScoreBand get band {
    // Perfect is its own tier and not just "high accuracy": on a two-challenge
    // section 1 of 2 is already 50%, and no rounding should ever let an
    // imperfect run congratulate itself as a clean one.
    if (isScored && correct == total) return LabScoreBand.perfect;
    if (accuracy >= strongThreshold) return LabScoreBand.strong;
    if (accuracy >= gettingThereThreshold) return LabScoreBand.gettingThere;
    return LabScoreBand.needsReview;
  }
}
