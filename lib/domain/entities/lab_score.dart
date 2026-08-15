// Domain layer: How a finished lab went, counted in the steps the learner
// actually walked through.
//
// The number that closes a lab is `completedSteps of totalSteps`, and every
// step of the lesson is in it — the explanations included. An explanation is
// not an exercise, but reading it IS progress, and a learner who walked
// through five screens and was shown a denominator of two had no way to tell
// whether the number was broken or the explanations simply did not count.
//
// What separates the two kinds of step is how they are earned. An explanation
// counts as soon as it is acknowledged: there is nothing to get wrong on a
// screen whose whole interaction is "Got it". An exercise counts only when it
// was answered right on the FIRST check. Retrying until it is right is still
// how the lab advances — nobody closes a topic without arriving at the answer
// — so a plain "exercises solved" count would be N of N for everyone and would
// carry no information at all.
//
// Because explanations are always earned, a perfect run still means exactly
// what it says: every exercise right on the first try. Theory can never hand
// one out.

/// The plain-language tier a [LabScore] falls into.
///
/// It decides which message closes the lab, so the thresholds are a product
/// rule and live here rather than next to the colors that render them.
enum LabScoreBand {
  /// Every step earned, which means every exercise right on the first try.
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
    this.exercisesCorrect = 0,
    this.exercisesTotal = 0,
    this.concepts = 0,
  });

  /// A lab with no steps at all.
  const LabScore.empty()
    : exercisesCorrect = 0,
      exercisesTotal = 0,
      concepts = 0;

  /// Exercises answered right on the first check.
  final int exercisesCorrect;

  /// Exercises in the lab — the steps that could be got wrong.
  final int exercisesTotal;

  /// Explanations read on the way through. Always earned, never gradable.
  final int concepts;

  /// Accuracy at or above which a run reads as [LabScoreBand.strong].
  static const double strongThreshold = 0.8;

  /// Accuracy at or above which a run reads as [LabScoreBand.gettingThere].
  static const double gettingThereThreshold = 0.5;

  /// Steps of the lesson that went well: every explanation read, plus the
  /// exercises answered right on the first try. This is the numerator shown.
  int get completedSteps => exercisesCorrect + concepts;

  /// Every step of the lesson. This is the denominator shown, and it matches
  /// the number of screens the learner walked through.
  int get totalSteps => exercisesTotal + concepts;

  /// Whether anything in this lab could be got wrong.
  ///
  /// A section made only of explanations has no performance to report: it
  /// would score a full house for reading, and calling that a perfect run
  /// would congratulate something that was never at stake.
  bool get hasExercises => exercisesTotal > 0;

  /// Exercises that took more than one try.
  int get missed => exercisesTotal - exercisesCorrect;

  /// Share of the lesson's steps that went well, 0.0 to 1.0.
  double get accuracy => totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

  /// [accuracy] as a whole percentage, for display.
  int get percentage => (accuracy * 100).round();

  LabScoreBand get band {
    // Perfect is its own tier and not just "high accuracy": no rounding should
    // ever let a run with a retry in it congratulate itself as a clean one.
    // Since explanations are always earned, this holds iff every exercise was
    // right on the first try.
    if (totalSteps > 0 && completedSteps == totalSteps) {
      return LabScoreBand.perfect;
    }
    if (accuracy >= strongThreshold) return LabScoreBand.strong;
    if (accuracy >= gettingThereThreshold) return LabScoreBand.gettingThere;
    return LabScoreBand.needsReview;
  }
}
