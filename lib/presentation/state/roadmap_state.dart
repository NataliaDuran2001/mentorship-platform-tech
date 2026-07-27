// Capa Presentation (State): Estado del árbol de tópicos del roadmap.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/topic_node.dart';

/// Árbol del track de la usuaria, ya anidado y con el estado secuencial puesto
/// por GetRoadmapTreeUseCase.
final roadmapTree = signal<List<TopicNode>>(<TopicNode>[]);

/// Cargando el árbol.
final roadmapLoading = signal<bool>(false);

/// Mensaje de error en español. `null` si no hay.
final roadmapError = signal<String?>(null);

/// Ya se intentó cargar al menos una vez.
///
/// Distingue «todavía no cargué» de «cargué y no hay nada»: sin esto, el estado
/// vacío parpadearía en la primera pintada.
final roadmapLoaded = signal<bool>(false);

/// Todos los tópicos hoja del árbol, en orden.
///
/// El avance se cuenta sobre las hojas y no sobre todos los nodos: un módulo con
/// tres tópicos adentro no es una cuarta cosa que completar, es el conjunto de
/// esos tres. Contarlo doblaría el denominador.
final roadmapLeaves = computed<List<TopicNode>>(() {
  return [
    for (final raiz in roadmapTree.value)
      ...raiz.flattened.where((nodo) => nodo.isLeaf),
  ];
});

/// Cuántas hojas están completadas.
final roadmapCompletedCount =
    computed(() => roadmapLeaves.value.where((n) => n.isCompleted).length);

/// Fracción de avance, de 0 a 1. Cero si el track todavía no tiene tópicos.
final roadmapProgress = computed(() {
  final total = roadmapLeaves.value.length;
  if (total == 0) return 0.0;
  return roadmapCompletedCount.value / total;
});

/// El track no tiene tópicos cargados.
///
/// Es el caso normal hoy para backend e infrastructure: el currículum es una
/// decisión abierta del Módulo 2.
final roadmapIsEmpty = computed(
  () => roadmapLoaded.value && roadmapTree.value.isEmpty,
);

/// Deja el roadmap como recién abierto. Se llama al cerrar sesión.
void resetRoadmap() {
  roadmapTree.value = <TopicNode>[];
  roadmapLoading.value = false;
  roadmapError.value = null;
  roadmapLoaded.value = false;
}
