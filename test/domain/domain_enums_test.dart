// Unit tests of the Module 1 enums (issue #8, AC5): they have to cover
// exactly the decided values, not one more.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';

void main() {
  test(
      'there are exactly 5 tracks covering the full delivery cycle, '
      'with the original three first (the tie-break depends on their order)',
      () {
    expect(RoadmapTrack.values.map((t) => t.slug), [
      'frontend',
      'backend',
      'infrastructure',
      'uiux',
      'project_management',
    ]);
  });

  test('there are exactly 4 experience levels', () {
    // The order is the order they are offered in, and 'other' goes last: it is
    // the way out for whoever recognizes herself in none of the three, not a
    // peer of them. Adding a value here also means adding it to the
    // `public.experience_level` enum in the database, or the write fails.
    expect(ExperienceLevel.values.map((l) => l.slug), [
      'student',
      'junior_developer',
      'career_switcher',
      'other',
    ]);
  });

  test('there are exactly 4 learning goals', () {
    expect(LearningGoal.values.map((g) => g.slug), [
      'first_job',
      'new_language',
      'interview_skills',
      'middle_level',
    ]);
  });

  test('fromSlug is the inverse of slug in the three enums', () {
    for (final track in RoadmapTrack.values) {
      expect(RoadmapTrack.fromSlug(track.slug), track);
    }
    for (final level in ExperienceLevel.values) {
      expect(ExperienceLevel.fromSlug(level.slug), level);
    }
    for (final goal in LearningGoal.values) {
      expect(LearningGoal.fromSlug(goal.slug), goal);
    }
  });

  test('fromSlug tolerates null and unknown values', () {
    expect(RoadmapTrack.fromSlug(null), isNull);
    expect(RoadmapTrack.fromSlug('mobile'), isNull);
    expect(RoadmapTrack.fromSlug('unknown'), isNull);
    expect(ExperienceLevel.fromSlug('senior'), isNull);
    expect(LearningGoal.fromSlug(''), isNull);
  });
}
