// Capa Domain: Caso de uso que encapsula una regla de negocio de la app.
//
// Arma el árbol de tópicos de un track a partir de la lista plana que entrega
// el repositorio, y le deriva la secuencialidad.
//
// La jerarquía y el «qué está desbloqueado» son reglas de negocio, no detalles
// de presentación: si vivieran en el widget del issue #13 no se podrían
// testear sin montar Flutter, y cada pantalla nueva podría interpretarlas
// distinto.

import '../entities/roadmap_track.dart';
import '../entities/topic_node.dart';
import '../repositories/roadmap_repository.dart';

class GetRoadmapTreeUseCase {
  const GetRoadmapTreeUseCase(this.repository);

  final RoadmapRepository repository;

  /// Tópicos de primer nivel del track, con sus hijos anidados, ordenados y
  /// con el estado secuencial ya resuelto.
  Future<List<TopicNode>> call(RoadmapTrack track) async {
    final flat = await repository.listTopics(track);
    return buildTree(flat);
  }

  /// Convierte la lista plana en árbol y deriva el estado de cada nodo.
  ///
  /// Expuesto aparte del [call] para poder testear la regla sin repositorio.
  List<TopicNode> buildTree(List<TopicNode> flat) {
    final byParent = <String?, List<TopicNode>>{};
    final knownIds = flat.map((node) => node.id).toSet();

    for (final node in flat) {
      // Un `parentId` que no está en la lista se trata como raíz: preferimos
      // mostrar el tópico huérfano que hacerlo desaparecer en silencio.
      final parent =
          knownIds.contains(node.parentId) ? node.parentId : null;
      byParent.putIfAbsent(parent, () => <TopicNode>[]).add(node);
    }

    List<TopicNode> childrenOf(String? parentId) {
      final siblings = byParent[parentId] ?? const <TopicNode>[];
      final ordered = [...siblings]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return [
        for (final node in ordered)
          node.copyWith(children: childrenOf(node.id)),
      ];
    }

    return _deriveStatus(childrenOf(null));
  }

  /// Marca el primer tópico hoja sin completar como [TopicStatus.available] y
  /// todos los siguientes como [TopicStatus.locked]. Un nodo con hijos hereda:
  /// está completado si todos sus hijos lo están, disponible si alguno de
  /// ellos lo está, y bloqueado en cualquier otro caso.
  List<TopicNode> _deriveStatus(List<TopicNode> roots) {
    var availableTaken = false;

    TopicNode visit(TopicNode node) {
      if (node.isLeaf) {
        if (node.isCompleted) {
          return node.copyWith(status: TopicStatus.completed);
        }
        if (!availableTaken) {
          availableTaken = true;
          return node.copyWith(status: TopicStatus.available);
        }
        return node.copyWith(status: TopicStatus.locked);
      }

      final children = [for (final child in node.children) visit(child)];

      final TopicStatus status;
      if (children.every((c) => c.status == TopicStatus.completed)) {
        status = TopicStatus.completed;
      } else if (children.any((c) => c.status == TopicStatus.available)) {
        status = TopicStatus.available;
      } else {
        status = TopicStatus.locked;
      }

      return node.copyWith(children: children, status: status);
    }

    return [for (final root in roots) visit(root)];
  }
}
