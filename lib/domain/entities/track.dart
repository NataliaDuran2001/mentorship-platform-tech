// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Datos editoriales de un track, tal como vienen de la tabla `tracks`: el
// título y la descripción que se muestran en las cards del paso 2 y del
// cuestionario guía. El enum [RoadmapTrack] identifica el track; esta entidad
// le cuelga el contenido.

import 'roadmap_track.dart';

class Track {
  const Track({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
  });

  final RoadmapTrack id;

  /// Nombre visible, en español, tal como está sembrado en la base.
  final String name;
  final String description;

  /// Nombre del ícono de Material que le corresponde. Es texto y no un
  /// `IconData` porque `domain` no puede importar Flutter; la capa
  /// Presentation lo resuelve.
  final String? iconName;
}
