// Capa Presentation (State): Acciones del roadmap.

import '../../core/di/injection.dart';
import '../../domain/usecases/get_roadmap_tree_usecase.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'roadmap_state.dart';

/// Carga el árbol de tópicos del track de la usuaria.
///
/// El track sale del perfil: si no hay, no hay nada que cargar y los route
/// guards ya se encargaron de que eso no pase con el onboarding completo.
Future<void> loadRoadmap() async {
  final track = currentProfile.value?.track;
  if (track == null) {
    roadmapTree.value = const [];
    roadmapLoaded.value = true;
    return;
  }

  roadmapLoading.value = true;
  roadmapError.value = null;

  try {
    // El caso de uso arma la jerarquía y deriva el estado secuencial; acá no se
    // ordena ni se decide qué está desbloqueado.
    roadmapTree.value = await getIt<GetRoadmapTreeUseCase>()(track);
    roadmapLoaded.value = true;
  } catch (e) {
    roadmapError.value = mensajeDeError(e);
  } finally {
    roadmapLoading.value = false;
  }
}

/// Reintenta la carga después de un error.
Future<void> retryRoadmap() {
  roadmapError.value = null;
  return loadRoadmap();
}
