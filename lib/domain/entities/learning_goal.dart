// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Las 4 metas del paso 3 del onboarding, exactamente las del prototipo
// `descubre_tu_ruta_onboarding`. El `slug` se persiste en
// `profiles.learning_goal`.

enum LearningGoal {
  /// Conseguir su primer empleo profesional.
  firstJob('first_job'),

  /// Aprender un nuevo lenguaje de programación.
  newLanguage('new_language'),

  /// Mejorar sus habilidades de entrevista técnica.
  interviewSkills('interview_skills'),

  /// Escalar a un puesto de nivel middle.
  middleLevel('middle_level');

  const LearningGoal(this.slug);

  /// Valor estable para persistencia. Nunca cambiar sin migrar los datos.
  final String slug;

  /// Devuelve la meta cuyo [slug] coincide, o `null` si no hay ninguna.
  static LearningGoal? fromSlug(String? slug) {
    for (final goal in LearningGoal.values) {
      if (goal.slug == slug) return goal;
    }
    return null;
  }
}
