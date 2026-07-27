// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Una respuesta suelta del onboarding. Se guarda al momento de seleccionarla,
// no al final, para que el flujo sea reanudable (issue #14).

/// Claves estables de los pasos del onboarding.
///
/// Son la clave de upsert de `onboarding_answers` junto con la usuaria: volver
/// atrás y cambiar una respuesta actualiza la fila, no agrega otra.
abstract final class OnboardingKeys {
  /// Paso 1: nivel de experiencia.
  static const String experienceLevel = 'experience_level';

  /// Paso 2: track elegido directamente.
  static const String track = 'track';

  /// Paso 3: meta de aprendizaje.
  static const String goal = 'goal';

  /// Valor del paso 2 cuando la usuaria elige «Aún no lo sé» y se deriva al
  /// cuestionario guía. No corresponde a ningún `RoadmapTrack`, y por eso
  /// `RoadmapTrack.fromSlug` devuelve `null` para él.
  static const String unknownTrackValue = 'unknown';

  /// Valor de un paso que la usuaria **omitió** a propósito.
  ///
  /// Se guarda para que la reanudación pueda distinguir «lo salteé» de «no
  /// llegué»: sin este rastro, volver al onboarding devolvería a la usuaria a un
  /// paso que ya decidió no responder.
  static const String skippedValue = 'skipped';

  /// Prefijo de las preguntas del cuestionario guía (issue #12), que son
  /// varias y numeradas: `quiz_1`, `quiz_2`, …
  static const String quizPrefix = 'quiz_';

  /// Clave de la pregunta [number] del cuestionario guía, empezando en 1.
  static String quizQuestion(int number) => '$quizPrefix$number';
}

class OnboardingAnswer {
  const OnboardingAnswer({
    required this.stepKey,
    required this.value,
    this.answeredAt,
  });

  /// Cuál paso o pregunta se respondió. Ver [OnboardingKeys].
  final String stepKey;

  /// Slug de la opción elegida. Se guarda como texto para que el mismo par
  /// (paso, valor) sirva a los pasos directos y a las preguntas del guía.
  final String value;

  /// Cuándo se respondió. `null` mientras la respuesta no viene de la base.
  final DateTime? answeredAt;
}
