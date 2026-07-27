// Pruebas del árbol de tópicos secuenciales (issue #13).
//
// Lo que se verifica es que la pantalla **respete** la secuencialidad que
// GetRoadmapTreeUseCase derivó: los tres estados distinguibles y los bloqueados
// sin responder al tap. La regla en sí ya está probada en
// test/domain/get_roadmap_tree_usecase_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/topic_node.dart';
import 'package:aspire_app/domain/entities/track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/roadmap_repository.dart';
import 'package:aspire_app/domain/usecases/get_roadmap_tree_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/roadmap_state.dart';
import 'package:aspire_app/presentation/widgets/organisms/roadmap_tree.dart';
import 'package:aspire_app/presentation/widgets/pages/roadmap_page.dart';

/// Repositorio en memoria. Devuelve la lista **plana**, como el contrato.
class FakeRoadmapRepository implements RoadmapRepository {
  FakeRoadmapRepository({this.topics = const [], this.fallo});

  List<TopicNode> topics;
  AuthFailure? fallo;
  int llamadas = 0;

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) async {
    llamadas++;
    if (fallo != null) throw fallo!;
    return topics.where((t) => t.trackId == track).toList();
  }

  @override
  Future<List<Track>> listTracks() async => const <Track>[];
}

TopicNode _nodo(
  String id, {
  String? parentId,
  int sortOrder = 0,
  bool isCompleted = false,
}) {
  return TopicNode(
    id: id,
    trackId: RoadmapTrack.frontend,
    parentId: parentId,
    title: id,
    sortOrder: sortOrder,
    isCompleted: isCompleted,
  );
}

/// Los 5 tópicos placeholder que la migración del #7 siembra en frontend.
final _placeholders = [
  _nodo('Módulo A', sortOrder: 1),
  _nodo('Tópico A1', parentId: 'Módulo A', sortOrder: 1, isCompleted: true),
  _nodo('Tópico A2', parentId: 'Módulo A', sortOrder: 2),
  _nodo('Módulo B', sortOrder: 2),
  _nodo('Tópico B1', parentId: 'Módulo B', sortOrder: 1),
];

Future<void> _montar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: RoadmapPage())),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeRoadmapRepository repo;

  setUp(() {
    repo = FakeRoadmapRepository();
    overrideDependency<RoadmapRepository>(repo);
    overrideDependency(GetRoadmapTreeUseCase(repo));

    resetRoadmap();
    currentProfile.value = const UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      track: RoadmapTrack.frontend,
    );
  });

  group('Despliegue del árbol', () {
    testWidgets('muestra la jerarquía y el orden de sort_order',
        (tester) async {
      repo.topics = _placeholders;
      await _montar(tester);

      expect(find.text('Front-end'), findsOneWidget);
      for (final titulo in [
        'Módulo A',
        'Tópico A1',
        'Tópico A2',
        'Módulo B',
        'Tópico B1',
      ]) {
        expect(find.text(titulo), findsOneWidget);
      }

      // El orden vertical refleja sort_order: Módulo A antes que Módulo B.
      final yA = tester.getTopLeft(find.text('Módulo A')).dy;
      final yB = tester.getTopLeft(find.text('Módulo B')).dy;
      expect(yA, lessThan(yB));

      // Y los hijos quedan indentados respecto a su módulo.
      final xModulo = tester.getTopLeft(find.text('Módulo A')).dx;
      final xHijo = tester.getTopLeft(find.text('Tópico A1')).dx;
      expect(xHijo, greaterThan(xModulo));
    });

    testWidgets('los tres estados son visualmente distinguibles',
        (tester) async {
      repo.topics = _placeholders;
      await _montar(tester);

      // Completado, disponible y bloqueado, cada uno con su leyenda y su ícono.
      // Se distinguen por forma además de por color.
      expect(find.text('Completado'), findsWidgets);
      expect(find.text('Disponible'), findsWidgets);
      expect(find.text('Bloqueado'), findsWidgets);

      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.byIcon(Icons.play_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('hay un solo tópico disponible y los bloqueados no responden '
        'al tap', (tester) async {
      repo.topics = _placeholders;
      final tocados = <String>[];

      await _montar(tester);

      // Se monta el organismo suelto para poder pasarle el callback.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoadmapTree(
                roots: roadmapTree.value,
                onTopicTap: (n) => tocados.add(n.id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A1 está completado, A2 es el disponible, B1 está bloqueado.
      await tester.tap(find.text('Tópico B1'));
      await tester.pumpAndSettle();
      expect(tocados, isEmpty, reason: 'un bloqueado no debe ser accionable');

      await tester.tap(find.text('Tópico A2'));
      await tester.pumpAndSettle();
      expect(tocados, ['Tópico A2']);
    });
  });

  group('Porcentaje de avance', () {
    testWidgets('calcula sobre las hojas completadas', (tester) async {
      repo.topics = _placeholders;
      await _montar(tester);

      // 3 hojas (A1, A2, B1), una completada → 33%.
      expect(roadmapLeaves.value, hasLength(3));
      expect(roadmapCompletedCount.value, 1);
      expect(find.textContaining('33% completado'), findsOneWidget);
      expect(find.textContaining('1 de 3 tópicos'), findsOneWidget);
    });

    testWidgets('con todo completado llega al 100%', (tester) async {
      repo.topics = [
        _nodo('Módulo A', sortOrder: 1),
        _nodo('A1', parentId: 'Módulo A', sortOrder: 1, isCompleted: true),
        _nodo('A2', parentId: 'Módulo A', sortOrder: 2, isCompleted: true),
      ];
      await _montar(tester);

      expect(find.textContaining('100% completado'), findsOneWidget);
      expect(find.text('Bloqueado'), findsNothing);
    });
  });

  group('Estado vacío', () {
    testWidgets('sin tópicos no muestra pantalla en blanco ni error',
        (tester) async {
      // Es el caso real hoy para backend e infrastructure.
      repo.topics = const [];
      await _montar(tester);

      expect(roadmapIsEmpty.value, isTrue);
      expect(find.byType(RoadmapEmptyState), findsOneWidget);
      expect(
        find.textContaining('Tu ruta de Front-end se está armando'),
        findsOneWidget,
      );
      expect(find.byType(RoadmapErrorState), findsNothing);
      // Y no se muestra un 0% que parecería un fracaso.
      expect(find.textContaining('% completado'), findsNothing);
    });
  });

  group('Error de carga', () {
    testWidgets('muestra el mensaje traducido y permite reintentar',
        (tester) async {
      repo.fallo = const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'SocketException: Failed host lookup',
      );

      await _montar(tester);

      expect(find.byType(RoadmapErrorState), findsOneWidget);
      expect(find.textContaining('No pudimos conectarnos'), findsOneWidget);
      // Nada del error crudo a la vista.
      expect(find.textContaining('SocketException'), findsNothing);

      // El reintento vuelve a pedir los datos; esta vez con éxito.
      repo.fallo = null;
      repo.topics = _placeholders;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(repo.llamadas, 2);
      expect(find.byType(RoadmapErrorState), findsNothing);
      expect(find.text('Módulo A'), findsOneWidget);
    });
  });

  group('Sin track', () {
    testWidgets('un perfil sin track no rompe la pantalla', (tester) async {
      currentProfile.value = const UserProfile(
        id: 'u1',
        email: 'ana@example.com',
      );

      await _montar(tester);

      // No se llamó al repositorio y se muestra el estado vacío.
      expect(repo.llamadas, 0);
      expect(find.byType(RoadmapEmptyState), findsOneWidget);
    });
  });
}
