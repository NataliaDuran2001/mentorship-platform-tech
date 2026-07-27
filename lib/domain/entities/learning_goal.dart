// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The 4 goals of onboarding step 3, exactly the ones from the
// `descubre_tu_ruta_onboarding` prototype. The `slug` is persisted in
// `profiles.learning_goal`.

enum LearningGoal {
  /// Land their first professional job.
  firstJob('first_job'),

  /// Learn a new programming language.
  newLanguage('new_language'),

  /// Improve their technical interview skills.
  interviewSkills('interview_skills'),

  /// Move up to a middle-level position.
  middleLevel('middle_level');

  const LearningGoal(this.slug);

  /// Stable value for persistence. Never change it without migrating data.
  final String slug;

  /// Returns the goal whose [slug] matches, or `null` if there is none.
  static LearningGoal? fromSlug(String? slug) {
    for (final goal in LearningGoal.values) {
      if (goal.slug == slug) return goal;
    }
    return null;
  }
}
