// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// The 5 roadmap tracks, covering the full software delivery cycle. Product
// decision of 2026-08-14: the original "3 technical tracks only" scope was
// reopened by the owner to add UI/UX and Project Management. Mobile remains
// out.
//
// The `slug` is also the primary key of the `tracks` table and the value of
// `profiles.track_id`, so that the mapping between enum and database is
// direct and needs no translation table.
//
// Declaration order matters: RecommendTrackUseCase breaks ties by it. New
// tracks go at the end so the tie-break among the original three is unchanged.

enum RoadmapTrack {
  /// Visual interfaces and user experience.
  frontend('frontend'),

  /// Server logic, APIs and databases.
  backend('backend'),

  /// Automation, deployment and systems operation.
  infrastructure('infrastructure'),

  /// Product design: research, interfaces and usability.
  uiux('uiux'),

  /// Planning and leading software projects (PMBOK + soft skills).
  projectManagement('project_management');

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
