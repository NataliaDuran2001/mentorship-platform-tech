// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The experience levels of Module 1. The first three are exactly the ones
// from the `descubre_tu_ruta_onboarding` prototype; `other` was added after
// the first beta, where the three closed options left anyone who recognized
// herself in none of them with only two ways out: force a wrong answer or
// skip the step.
//
// `other` carries no meaning of its own: what it means is in the free text the
// user writes, which is persisted in `onboarding_answers` under the
// `experience_other` key. This enum stays a plain list of slugs.
//
// The `slug` is the stable value that travels to the database: the Data
// layer persists it as-is in `profiles.experience_level`. The visible
// labels live in the Presentation layer, not here.

enum ExperienceLevel {
  /// Student / self-taught: learning the basics, looking for a first job.
  student('student'),

  /// Junior developer: less than 2 years of professional experience.
  juniorDeveloper('junior_developer'),

  /// Career switcher: comes from another sector and wants to enter tech.
  careerSwitcher('career_switcher'),

  /// None of the above: the reason is in her own words.
  other('other');

  const ExperienceLevel(this.slug);

  /// Stable value for persistence. Never change it without migrating data.
  final String slug;

  /// Returns the level whose [slug] matches, or `null` if there is none.
  ///
  /// It tolerates `null` and unknown values on purpose: a half-filled
  /// profile or an old row must not blow up the read.
  static ExperienceLevel? fromSlug(String? slug) {
    for (final level in ExperienceLevel.values) {
      if (level.slug == slug) return level;
    }
    return null;
  }
}
