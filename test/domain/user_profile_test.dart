// Unit tests of the rule that holds up the route guards of issue #9: a
// profile without a track does not count as a complete onboarding, no matter
// that it has the timestamp.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';

void main() {
  const base = UserProfile(id: 'u1', email: 'ana@example.com');

  test('a freshly created profile does not have the onboarding complete', () {
    expect(base.hasCompletedOnboarding, isFalse);
    expect(base.track, isNull);
    expect(base.onboardingCompletedAt, isNull);
  });

  test('with a timestamp but no track it is still incomplete', () {
    final profile = base.copyWith(onboardingCompletedAt: DateTime(2026, 7, 26));

    expect(profile.hasCompletedOnboarding, isFalse);
  });

  test('with a track but no timestamp it is still incomplete', () {
    final profile = base.copyWith(track: RoadmapTrack.backend);

    expect(profile.hasCompletedOnboarding, isFalse);
  });

  test('with a track and a timestamp it is complete', () {
    final profile = base.copyWith(
      experienceLevel: ExperienceLevel.juniorDeveloper,
      track: RoadmapTrack.frontend,
      learningGoal: LearningGoal.interviewSkills,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );

    expect(profile.hasCompletedOnboarding, isTrue);
  });

  test('copyWith keeps the identity and whatever is not specified', () {
    final profile = base.copyWith(displayName: 'Ana');

    expect(profile.id, base.id);
    expect(profile.email, base.email);
    expect(profile.displayName, 'Ana');
    expect(profile.track, isNull);
  });
}
