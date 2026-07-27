// Capa Data: Modelo que parsea un tópico desde la tabla `topics` y se mapea a
// la entidad TopicNode de la capa Domain.
//
// El modelo NO arma la jerarquía ni decide el estado secuencial: devuelve el
// nodo plano con `isCompleted` resuelto. Anidar por `parentId`, ordenar por
// `sortOrder` y derivar `TopicStatus` es de GetRoadmapTreeUseCase, porque son
// reglas de negocio y no detalles de parseo.

import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/topic_node.dart';

class TopicModel {
  const TopicModel({
    required this.id,
    required this.trackId,
    required this.title,
    required this.sortOrder,
    this.parentId,
    this.description,
  });

  /// Columnas del `select`. Explícitas y no `*`: agregar una columna a la tabla
  /// no debe cambiar en silencio lo que viaja al cliente.
  static const String columns =
      'id, track_id, parent_id, title, description, sort_order';

  final String id;
  final String trackId;
  final String? parentId;
  final String title;
  final String? description;
  final int sortOrder;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      trackId: json['track_id'] as String,
      parentId: json['parent_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convierte a entidad. [isCompleted] viene de `user_progress`, no de esta
  /// tabla: el tópico es el mismo para todas, el avance es de cada usuaria.
  ///
  /// Un `track_id` que el enum no conoce se descarta devolviendo `null`: es más
  /// seguro no mostrar un tópico que la app no entiende que inventarle un track.
  TopicNode? toEntity({bool isCompleted = false}) {
    final track = RoadmapTrack.fromSlug(trackId);
    if (track == null) return null;

    return TopicNode(
      id: id,
      trackId: track,
      parentId: parentId,
      title: title,
      description: description,
      sortOrder: sortOrder,
      isCompleted: isCompleted,
    );
  }
}
