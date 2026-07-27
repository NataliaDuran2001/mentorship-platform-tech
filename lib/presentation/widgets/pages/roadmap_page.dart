// Atomic Design (Página): Estructura principal que une organismos y maneja
// la inyección de dependencias y el estado global o de la vista.
//
// La ruta de aprendizaje: el árbol de tópicos secuenciales del track elegido.
// Es lo que cierra el CA 1.3 de la Historia 1.1 —«al definir la ruta se despliega
// el árbol de tópicos secuenciales»—, y por eso es el destino al que llega la
// usuaria al terminar el onboarding.

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_state.dart';
import '../../state/roadmap_actions.dart';
import '../../state/roadmap_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../atoms/app_progress_bar.dart';
import '../organisms/roadmap_tree.dart';

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        // Carga perezosa la primera vez que se pinta. No se llama sin más en el
        // builder: eso dispararía una carga en cada reconstrucción.
        if (!roadmapLoaded.value &&
            !roadmapLoading.value &&
            roadmapError.value == null) {
          // Fuera del ciclo de build actual, para no cambiar señales mientras se
          // está construyendo.
          WidgetsBinding.instance.addPostFrameCallback((_) => loadRoadmap());
        }

        final nombreDelTrack =
            nombreDeTrack(currentProfile.value?.track) ?? 'tu especialidad';

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(trackName: nombreDelTrack),
              const SizedBox(height: AppConstants.spacingLg),
              if (roadmapLoading.value)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacingXl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (roadmapError.value != null)
                RoadmapErrorState(
                  message: roadmapError.value!,
                  onRetry: retryRoadmap,
                )
              else if (roadmapIsEmpty.value)
                RoadmapEmptyState(trackName: nombreDelTrack)
              else
                RoadmapTree(roots: roadmapTree.value),
            ],
          ),
        );
      },
    );
  }
}

/// Título, track y porcentaje de avance.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.trackName});

  final String trackName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = roadmapLeaves.value.length;
    final completados = roadmapCompletedCount.value;
    final porcentaje = (roadmapProgress.value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tu ruta'.toUpperCase(),
          style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(trackName, style: textTheme.headlineMedium),
        const SizedBox(height: AppConstants.spacingMd),
        // Sin tópicos no se muestra un 0% que parecería un fracaso: no hay
        // contra qué medir todavía.
        if (total > 0) ...[
          AppProgressBar(
            value: roadmapProgress.value,
            semanticsLabel: 'Avance de tu ruta',
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            '$porcentaje% completado · $completados de $total tópicos',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
