// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// A single onboarding answer. It is saved the moment it is selected, not at
// the end, so that the flow is resumable (issue #14).

/// Stable keys of the onboarding steps.
///
/// Together with the user they are the upsert key of `onboarding_answers`:
/// going back and changing an answer updates the row instead of adding one.
abstract final class OnboardingKeys {
  /// Step 1: experience level.
  static const String experienceLevel = 'experience_level';

  /// Step 0: interface language.
  ///
  /// The choice itself lives in `profiles.language`, which is what the app
  /// reads. This row exists only so resuming can tell "already asked" from
  /// "never got there": every profile is born with `language = 'en'`, so the
  /// stored value alone cannot say whether anyone chose it.
  static const String language = 'language';

  /// Step 2: track chosen directly.
  static const String track = 'track';

  /// Step 3: learning goal.
  static const String goal = 'goal';

  /// Value of step 2 when the user picks the "not sure yet" option and is
  /// routed to the guided quiz. It does not correspond to any
  /// `RoadmapTrack`, which is why `RoadmapTrack.fromSlug` returns `null`
  /// for it.
  static const String unknownTrackValue = 'unknown';

  /// Value of a step the user **skipped** on purpose.
  ///
  /// It is stored so that resuming can tell "I skipped it" from "I never got
  /// there": without this trace, coming back to the onboarding would send the
  /// user to a step she already decided not to answer.
  static const String skippedValue = 'skipped';

  /// Prefix of the guided quiz questions (issue #12), which are several and
  /// numbered: `quiz_1`, `quiz_2`, …
  static const String quizPrefix = 'quiz_';

  /// Key of question [number] of the guided quiz, starting at 1.
  static String quizQuestion(int number) => '$quizPrefix$number';
}

class OnboardingAnswer {
  const OnboardingAnswer({
    required this.stepKey,
    required this.value,
    this.answeredAt,
  });

  /// Which step or question was answered. See [OnboardingKeys].
  final String stepKey;

  /// Slug of the chosen option. Stored as text so that the same (step, value)
  /// pair serves both the direct steps and the guided quiz questions.
  final String value;

  /// When it was answered. `null` while the answer does not come from the
  /// database.
  final DateTime? answeredAt;
}
