// Capa Domain: Entidad pura de negocio (Dart puro, sin Flutter ni JSON).
//
// Nodo del árbol de tópicos de un roadmap. La jerarquía se arma por
// [TopicNode.parentId] y el orden entre hermanos por [TopicNode.sortOrder].

import 'roadmap_track.dart';

/// Estado secuencial de un tópico.
///
/// Es lo que hace que la ruta sea determinística en vez de un menú libre: solo
/// hay un tópico [available] a la vez y los [locked] no responden al tap.
enum TopicStatus {
  /// Ya completado por la usuaria.
  completed,

  /// El siguiente sin completar. Es el único accionable.
  available,

  /// Todavía no alcanzable: hay tópicos anteriores sin completar.
  locked,
}

class TopicNode {
  const TopicNode({
    required this.id,
    required this.trackId,
    required this.title,
    required this.sortOrder,
    this.parentId,
    this.description,
    this.isCompleted = false,
    this.children = const <TopicNode>[],
    this.status = TopicStatus.locked,
  });

  final String id;
  final RoadmapTrack trackId;

  /// Nodo padre, o `null` si es un tópico de primer nivel.
  final String? parentId;

  final String title;
  final String? description;

  /// Orden entre hermanos. No es único en todo el árbol, solo dentro del padre.
  final int sortOrder;

  /// Hecho crudo que viene de `user_progress`: la usuaria completó el tópico.
  final bool isCompleted;

  /// Hijos ya ordenados por [sortOrder]. Vacío en los nodos hoja y también
  /// mientras el árbol no se ha armado (la capa Data entrega una lista plana).
  final List<TopicNode> children;

  /// Estado derivado por `GetRoadmapTreeUseCase` al armar el árbol.
  ///
  /// El valor por defecto es [TopicStatus.locked] a propósito: un nodo que
  /// nadie evaluó no debe verse accionable.
  final TopicStatus status;

  bool get isLeaf => children.isEmpty;

  /// Este nodo y toda su descendencia, en orden de recorrido.
  Iterable<TopicNode> get flattened =>
      [this, for (final child in children) ...child.flattened];

  TopicNode copyWith({
    List<TopicNode>? children,
    TopicStatus? status,
    bool? isCompleted,
  }) {
    return TopicNode(
      id: id,
      trackId: trackId,
      parentId: parentId,
      title: title,
      description: description,
      sortOrder: sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      children: children ?? this.children,
      status: status ?? this.status,
    );
  }
}
