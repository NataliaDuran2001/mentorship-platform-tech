// Pruebas unitarias del armado del árbol y de la secuencialidad (issue #8).
// La regla que verifican es la que sostiene el CA 1.3: la ruta es
// determinística, con un solo tópico accionable a la vez.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/topic_node.dart';
import 'package:aspire_app/domain/entities/track.dart';
import 'package:aspire_app/domain/repositories/roadmap_repository.dart';
import 'package:aspire_app/domain/usecases/get_roadmap_tree_usecase.dart';

/// Repositorio en memoria: alcanza para probar la regla sin tocar Supabase.
class _FakeRoadmapRepository implements RoadmapRepository {
  _FakeRoadmapRepository(this.topics);

  final List<TopicNode> topics;

  @override
  Future<List<Track>> listTracks() async => const <Track>[];

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) async =>
      topics.where((t) => t.trackId == track).toList();
}

TopicNode _nodo(
  String id, {
  String? parentId,
  int sortOrder = 0,
  bool isCompleted = false,
  RoadmapTrack track = RoadmapTrack.frontend,
}) {
  return TopicNode(
    id: id,
    trackId: track,
    parentId: parentId,
    title: id,
    sortOrder: sortOrder,
    isCompleted: isCompleted,
  );
}

void main() {
  const usecase = GetRoadmapTreeUseCase(_NoRepo());

  group('armado del árbol', () {
    test('anida por parentId y ordena hermanos por sortOrder', () {
      final tree = usecase.buildTree([
        _nodo('b', sortOrder: 2),
        _nodo('a', sortOrder: 1),
        _nodo('a2', parentId: 'a', sortOrder: 2),
        _nodo('a1', parentId: 'a', sortOrder: 1),
      ]);

      expect(tree.map((n) => n.id), ['a', 'b']);
      expect(tree.first.children.map((n) => n.id), ['a1', 'a2']);
      expect(tree.last.isLeaf, isTrue);
    });

    test('un parentId inexistente se trata como raíz, no se descarta', () {
      final tree = usecase.buildTree([
        _nodo('a', sortOrder: 1),
        _nodo('huerfano', parentId: 'no-existe', sortOrder: 2),
      ]);

      expect(tree.map((n) => n.id), ['a', 'huerfano']);
    });

    test('lista vacía devuelve árbol vacío', () {
      expect(usecase.buildTree(const []), isEmpty);
    });

    test('flattened recorre el nodo y toda su descendencia', () {
      final tree = usecase.buildTree([
        _nodo('a', sortOrder: 1),
        _nodo('a1', parentId: 'a', sortOrder: 1),
        _nodo('a1x', parentId: 'a1', sortOrder: 1),
      ]);

      expect(tree.first.flattened.map((n) => n.id), ['a', 'a1', 'a1x']);
    });
  });

  group('secuencialidad', () {
    test('solo el primer tópico sin completar queda disponible', () {
      final tree = usecase.buildTree([
        _nodo('t1', sortOrder: 1, isCompleted: true),
        _nodo('t2', sortOrder: 2),
        _nodo('t3', sortOrder: 3),
      ]);

      expect(tree.map((n) => n.status), [
        TopicStatus.completed,
        TopicStatus.available,
        TopicStatus.locked,
      ]);
    });

    test('sin nada completado el primero es el disponible', () {
      final tree = usecase.buildTree([
        _nodo('t1', sortOrder: 1),
        _nodo('t2', sortOrder: 2),
      ]);

      expect(tree.first.status, TopicStatus.available);
      expect(tree.last.status, TopicStatus.locked);
    });

    test('el orden que manda es sortOrder, no el de la lista', () {
      final tree = usecase.buildTree([
        _nodo('segundo', sortOrder: 2),
        _nodo('primero', sortOrder: 1),
      ]);

      expect(tree.first.id, 'primero');
      expect(tree.first.status, TopicStatus.available);
    });

    test('hay exactamente un tópico disponible en todo el árbol', () {
      final tree = usecase.buildTree([
        _nodo('a', sortOrder: 1),
        _nodo('a1', parentId: 'a', sortOrder: 1, isCompleted: true),
        _nodo('a2', parentId: 'a', sortOrder: 2),
        _nodo('b', sortOrder: 2),
        _nodo('b1', parentId: 'b', sortOrder: 1),
      ]);

      final hojas = tree
          .expand((n) => n.flattened)
          .where((n) => n.isLeaf)
          .toList();
      final disponibles =
          hojas.where((n) => n.status == TopicStatus.available).toList();

      expect(disponibles.map((n) => n.id), ['a2']);
    });

    test('un nodo con hijos hereda el estado de su descendencia', () {
      final tree = usecase.buildTree([
        _nodo('a', sortOrder: 1),
        _nodo('a1', parentId: 'a', sortOrder: 1, isCompleted: true),
        _nodo('b', sortOrder: 2),
        _nodo('b1', parentId: 'b', sortOrder: 1),
        _nodo('c', sortOrder: 3),
        _nodo('c1', parentId: 'c', sortOrder: 1),
      ]);

      // 'a' completo, 'b' contiene el disponible, 'c' queda bloqueado.
      expect(tree.map((n) => n.status), [
        TopicStatus.completed,
        TopicStatus.available,
        TopicStatus.locked,
      ]);
    });
  });

  test('call filtra por track y devuelve el árbol del track pedido', () async {
    final repo = _FakeRoadmapRepository([
      _nodo('fe1', sortOrder: 1),
      _nodo('be1', sortOrder: 1, track: RoadmapTrack.backend),
    ]);

    final tree = await GetRoadmapTreeUseCase(repo)(RoadmapTrack.backend);

    expect(tree.map((n) => n.id), ['be1']);
    expect(tree.first.status, TopicStatus.available);
  });
}

/// Repositorio inutilizable, para las pruebas que solo ejercitan `buildTree`.
class _NoRepo implements RoadmapRepository {
  const _NoRepo();

  @override
  Future<List<Track>> listTracks() => throw UnimplementedError();

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) =>
      throw UnimplementedError();
}
