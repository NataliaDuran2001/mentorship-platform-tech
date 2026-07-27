// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// Editorial data of a track, as it comes from the `tracks` table: the title
// and description shown in the cards of step 2 and of the guided quiz. The
// [RoadmapTrack] enum identifies the track; this entity hangs the content
// off it.

import 'roadmap_track.dart';

class Track {
  const Track({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
  });

  final RoadmapTrack id;

  /// Visible name, as seeded in the database.
  final String name;
  final String description;

  /// Name of the matching Material icon. It is text and not an `IconData`
  /// because `domain` cannot import Flutter; the Presentation layer resolves
  /// it.
  final String? iconName;
}
