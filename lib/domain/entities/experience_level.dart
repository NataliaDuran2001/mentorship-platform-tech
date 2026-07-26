// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Los 3 niveles de experiencia del Módulo 1. Son exactamente los del
// prototipo `descubre_tu_ruta_onboarding` y no admiten valores extra.
//
// El `slug` es el valor estable que viaja a la base de datos: la capa Data
// lo persiste tal cual en `profiles.experience_level`. Las etiquetas en
// español viven en la capa Presentation, no acá.

enum ExperienceLevel {
  /// Estudiante / autodidacta: aprendiendo las bases, busca su primer empleo.
  student('student'),

  /// Junior developer: menos de 2 años de experiencia profesional.
  juniorDeveloper('junior_developer'),

  /// Cambiando de carrera: viene de otro sector y quiere entrar a tech.
  careerSwitcher('career_switcher');

  const ExperienceLevel(this.slug);

  /// Valor estable para persistencia. Nunca cambiar sin migrar los datos.
  final String slug;

  /// Devuelve el nivel cuyo [slug] coincide, o `null` si no hay ninguno.
  ///
  /// Tolera `null` y valores desconocidos a propósito: un perfil a medio
  /// llenar o una fila vieja no debe hacer explotar la lectura.
  static ExperienceLevel? fromSlug(String? slug) {
    for (final level in ExperienceLevel.values) {
      if (level.slug == slug) return level;
    }
    return null;
  }
}
