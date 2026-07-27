// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The 3 roadmap tracks. Closed product decision: there is no Mobile and no
// UI/UX, even though they show up in the prototype mockups.
//
// The `slug` is also the primary key of the `tracks` table and the value of
// `profiles.track_id`, so that the mapping between enum and database is
// direct and needs no translation table.

enum RoadmapTrack {
  /// Visual interfaces and user experience.
  frontend('frontend'),

  /// Server logic, APIs and databases.
  backend('backend'),

  /// Automation, deployment and systems operation.
  infrastructure('infrastructure');

  const RoadmapTrack(this.slug);

  /// Stable value for persistence. Never change it without migrating data.
  final String slug;

  /// Returns the track whose [slug] matches, or `null` if there is none.
  ///
  /// Returning `null` is what allows the "not sure yet" option of onboarding
  /// step 2 (`OnboardingKeys.unknownTrackValue`) to be persisted as an answer
  /// without representing a track.
  static RoadmapTrack? fromSlug(String? slug) {
    for (final track in RoadmapTrack.values) {
      if (track.slug == slug) return track;
    }
    return null;
  }
}
