// Unit tests of UserRole (issue #36).
//
// The interesting case is not the happy path but the fallback: an unknown
// slug has to read as the LEAST privileged role. Getting that backwards would
// hand out admin on a typo.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/user_role.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';

void main() {
  test('there are exactly 2 roles: student and admin', () {
    expect(UserRole.values.map((r) => r.slug), ['student', 'admin']);
  });

  test('the slugs mirror the public.user_role enum of the database', () {
    expect(UserRole.fromSlug('student'), UserRole.student);
    expect(UserRole.fromSlug('admin'), UserRole.admin);
  });

  test('an unknown, empty or null slug falls back to student', () {
    expect(UserRole.fromSlug('superuser'), UserRole.student);
    expect(UserRole.fromSlug(''), UserRole.student);
    expect(UserRole.fromSlug(null), UserRole.student);
  });

  test('isAdmin only holds for admin', () {
    expect(UserRole.admin.isAdmin, isTrue);
    expect(UserRole.student.isAdmin, isFalse);
  });

  test('a profile built without a role is a student', () {
    const profile = UserProfile(id: 'u1', email: 'a@example.com');

    expect(profile.role, UserRole.student);
  });

  test('copyWith keeps the role: it cannot be changed from the client', () {
    const admin = UserProfile(
      id: 'u1',
      email: 'a@example.com',
      role: UserRole.admin,
    );

    expect(admin.copyWith(displayName: 'New name').role, UserRole.admin);
  });
}
