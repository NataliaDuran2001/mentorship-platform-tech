// Capa Domain: Caso de uso que encapsula una regla de negocio de la app.
//
// Traduce las respuestas del cuestionario guía a un track recomendado. Es la
// única lógica de negocio real del Módulo 1, y por eso vive acá y no en un
// widget: el issue #12 exige explícitamente que la decisión no se tome en la
// UI.

import '../entities/onboarding_answer.dart';
import '../entities/roadmap_track.dart';
import '../entities/track_recommendation.dart';

class RecommendTrackUseCase {
  const RecommendTrackUseCase();

  /// Cuenta un voto por cada respuesta cuyo valor corresponda a un track y
  /// devuelve el más votado.
  ///
  /// Acepta la lista completa de respuestas del onboarding, no solo las del
  /// cuestionario: las que no mapean a un track (`student`, `first_job`,
  /// `unknown`) simplemente no votan. Eso permite pasarle tal cual lo que
  /// devuelve `OnboardingRepository.loadAnswers()` al reanudar (issue #14) sin
  /// filtrar nada antes.
  ///
  /// Empates: gana el orden de declaración de [RoadmapTrack] —frontend,
  /// backend, infrastructure— y el resultado viene marcado con `wasTie: true`.
  /// El criterio es arbitrario a propósito; lo que importa es que sea
  /// **determinístico** y que el empate se pueda mostrar, porque el issue #12
  /// obliga a que la usuaria confirme la recomendación y pueda corregirla a
  /// mano. Frontend queda primero por ser la puerta de entrada más común para
  /// quien recién empieza, que es el perfil dominante del producto.
  TrackRecommendation call(List<OnboardingAnswer> answers) {
    final scores = <RoadmapTrack, int>{
      for (final track in RoadmapTrack.values) track: 0,
    };

    var votes = 0;
    for (final answer in answers) {
      final track = RoadmapTrack.fromSlug(answer.value);
      if (track == null) continue;
      scores[track] = scores[track]! + 1;
      votes++;
    }

    if (votes == 0) return const TrackRecommendation.empty();

    final highest = scores.values.reduce((a, b) => a > b ? a : b);
    final winners = RoadmapTrack.values
        .where((track) => scores[track] == highest)
        .toList(growable: false);

    return TrackRecommendation(
      track: winners.first,
      scores: scores,
      wasTie: winners.length > 1,
    );
  }
}
