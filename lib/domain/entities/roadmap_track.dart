// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Los 3 tracks del roadmap. Decisión de producto cerrada: no hay Mobile ni
// UI/UX, aunque aparezcan en los mockups del prototipo.
//
// El `slug` es además la clave primaria de la tabla `tracks` y el valor de
// `profiles.track_id`, para que el mapeo entre enum y base de datos sea
// directo y no necesite una tabla de traducción.

enum RoadmapTrack {
  /// Interfaces visuales y experiencia de usuario.
  frontend('frontend'),

  /// Lógica de servidor, APIs y bases de datos.
  backend('backend'),

  /// Automatización, despliegue y operación de sistemas.
  infrastructure('infrastructure');

  const RoadmapTrack(this.slug);

  /// Valor estable para persistencia. Nunca cambiar sin migrar los datos.
  final String slug;

  /// Devuelve el track cuyo [slug] coincide, o `null` si no hay ninguno.
  ///
  /// Devolver `null` es lo que permite que la opción «Aún no lo sé» del paso 2
  /// del onboarding (`OnboardingKeys.unknownTrackValue`) se persista como
  /// respuesta sin representar un track.
  static RoadmapTrack? fromSlug(String? slug) {
    for (final track in RoadmapTrack.values) {
      if (track.slug == slug) return track;
    }
    return null;
  }
}
