// Domain layer: Pure business entity (pure Dart, no Flutter, no JSON).
//
// What a user is allowed to be in the platform (issue #36). The student is the
// role everybody gets on sign-up; the admin is the one who loads the study
// material that the AI will turn into roadmaps (issue #37).
//
// The `slug` is the stable value that travels to the database: it mirrors the
// `public.user_role` enum. If one side changes, the other changes with it.
//
// Reading this enum tells you what a user IS, never what the app should let
// them do from the client. The real gate is the RLS policy in the database:
// the publishable key ships inside the web bundle, so anything enforced only
// here is a suggestion.

enum UserRole {
  student('student'),
  admin('admin');

  const UserRole(this.slug);

  final String slug;

  /// An unknown or missing slug reads as [UserRole.student].
  ///
  /// Defaulting to the least privileged role is deliberate: a row written by
  /// a newer version of the app must never grant more than it should.
  static UserRole fromSlug(String? slug) {
    for (final role in UserRole.values) {
      if (role.slug == slug) return role;
    }
    return UserRole.student;
  }

  bool get isAdmin => this == UserRole.admin;
}
