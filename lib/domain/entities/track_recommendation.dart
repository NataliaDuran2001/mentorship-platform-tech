// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Salida de `RecommendTrackUseCase`. Es una sugerencia, no una asignación: el
// issue #12 exige que la usuaria confirme el resultado y pueda corregirlo a
// mano antes de que se persista.

import 'roadmap_track.dart';

class TrackRecommendation {
  const TrackRecommendation({
    required this.track,
    required this.scores,
    required this.wasTie,
  });

  /// Sin respuestas utilizables no hay nada que recomendar.
  const TrackRecommendation.empty()
      : track = null,
        scores = const <RoadmapTrack, int>{
          RoadmapTrack.frontend: 0,
          RoadmapTrack.backend: 0,
          RoadmapTrack.infrastructure: 0,
        },
        wasTie = false;

  /// Track sugerido, o `null` si no hubo ninguna respuesta utilizable.
  final RoadmapTrack? track;

  /// Votos por track, incluidos los que sacaron cero.
  final Map<RoadmapTrack, int> scores;

  /// El puntaje máximo lo compartían dos o más tracks y [track] salió de un
  /// desempate. La UI debería decirlo en vez de presentar el resultado como
  /// concluyente.
  final bool wasTie;

  bool get hasRecommendation => track != null;
}
