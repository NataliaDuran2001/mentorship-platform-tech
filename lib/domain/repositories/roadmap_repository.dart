// Capa Domain: Contrato (interfaz) del repositorio de roadmaps.
// Define QUÉ se puede hacer, no CÓMO. La implementación vive en `data`.

import '../entities/roadmap_track.dart';
import '../entities/topic_node.dart';
import '../entities/track.dart';

abstract class RoadmapRepository {
  /// Los 3 tracks con su contenido editorial, tal como están sembrados en la
  /// tabla `tracks`.
  Future<List<Track>> listTracks();

  /// Tópicos de un track en **lista plana**, con `isCompleted` ya resuelto
  /// contra el progreso de la usuaria.
  ///
  /// Devuelve la lista plana y no el árbol armado a propósito: la jerarquía y
  /// la secuencialidad son reglas de negocio, así que las deriva
  /// `GetRoadmapTreeUseCase` y no la capa Data ni un widget.
  Future<List<TopicNode>> listTopics(RoadmapTrack track);
}
