// Pruebas unitarias de los enums del Módulo 1 (issue #8, AC5): tienen que
// cubrir exactamente los valores decididos, ni uno más.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';

void main() {
  test('hay exactamente 3 tracks: frontend, backend, infrastructure', () {
    expect(RoadmapTrack.values.map((t) => t.slug), [
      'frontend',
      'backend',
      'infrastructure',
    ]);
  });

  test('hay exactamente 3 niveles de experiencia', () {
    expect(ExperienceLevel.values.map((l) => l.slug), [
      'student',
      'junior_developer',
      'career_switcher',
    ]);
  });

  test('hay exactamente 4 metas de aprendizaje', () {
    expect(LearningGoal.values.map((g) => g.slug), [
      'first_job',
      'new_language',
      'interview_skills',
      'middle_level',
    ]);
  });

  test('fromSlug es inverso de slug en los tres enums', () {
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

  test('fromSlug tolera null y valores desconocidos', () {
    expect(RoadmapTrack.fromSlug(null), isNull);
    expect(RoadmapTrack.fromSlug('mobile'), isNull);
    expect(RoadmapTrack.fromSlug('unknown'), isNull);
    expect(ExperienceLevel.fromSlug('senior'), isNull);
    expect(LearningGoal.fromSlug(''), isNull);
  });
}
