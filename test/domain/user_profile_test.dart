// Pruebas unitarias de la regla que sostiene los route guards del issue #9:
// un perfil sin track no cuenta como onboarding completo, por más que tenga
// la marca de tiempo.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';

void main() {
  const base = UserProfile(id: 'u1', email: 'ana@example.com');

  test('un perfil recién creado no tiene el onboarding completo', () {
    expect(base.hasCompletedOnboarding, isFalse);
    expect(base.track, isNull);
    expect(base.onboardingCompletedAt, isNull);
  });

  test('con marca de tiempo pero sin track sigue incompleto', () {
    final perfil = base.copyWith(onboardingCompletedAt: DateTime(2026, 7, 26));

    expect(perfil.hasCompletedOnboarding, isFalse);
  });

  test('con track pero sin marca de tiempo sigue incompleto', () {
    final perfil = base.copyWith(track: RoadmapTrack.backend);

    expect(perfil.hasCompletedOnboarding, isFalse);
  });

  test('con track y marca de tiempo está completo', () {
    final perfil = base.copyWith(
      experienceLevel: ExperienceLevel.juniorDeveloper,
      track: RoadmapTrack.frontend,
      learningGoal: LearningGoal.interviewSkills,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );

    expect(perfil.hasCompletedOnboarding, isTrue);
  });

  test('copyWith conserva identidad y lo no especificado', () {
    final perfil = base.copyWith(displayName: 'Ana');

    expect(perfil.id, base.id);
    expect(perfil.email, base.email);
    expect(perfil.displayName, 'Ana');
    expect(perfil.track, isNull);
  });
}
