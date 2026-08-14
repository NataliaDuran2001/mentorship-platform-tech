// Guards the coupling between the RoadmapTrack enum and its presentation
// labels. Step 2 of the onboarding and the quiz's override chips iterate
// these maps: an enum value without an entry would crash with a null check
// the first time the screen is painted, which is exactly how a track added
// only in the database (or only in the enum) would slip through.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/presentation/utils/onboarding_labels.dart';

void main() {
  test('every track has a label, a description and an icon', () {
    expect(trackLabels.keys.toSet(), RoadmapTrack.values.toSet());

    for (final entry in trackLabels.entries) {
      expect(entry.value.label, isNotEmpty,
          reason: '${entry.key} has an empty label');
      expect(entry.value.description, isNotNull,
          reason: '${entry.key} has no description for its card');
    }
  });

  test('labels are unique: two tracks must never read the same', () {
    final labels = trackLabels.values.map((v) => v.label).toList();
    expect(labels.toSet().length, labels.length);
  });
}
