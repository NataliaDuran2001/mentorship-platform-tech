// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The UI language the student chose in Settings. Drives both the app's own
// text (via `tr()` in the presentation layer) and what language the AI
// Edge Functions are asked to answer in.
//
// The `slug` is also the value of `profiles.language`, so the mapping
// between enum and database is direct and needs no translation table.

enum AppLanguage {
  en('en'),
  es('es');

  const AppLanguage(this.slug);

  /// Stable value for persistence. Never change it without migrating data.
  final String slug;

  /// Returns the language whose [slug] matches, or `AppLanguage.en` for a
  /// `null`/unknown slug — English is the app's original baseline, so a
  /// stale or missing value falls back to it instead of breaking.
  static AppLanguage fromSlug(String? slug) {
    for (final language in AppLanguage.values) {
      if (language.slug == slug) return language;
    }
    return AppLanguage.en;
  }
}
