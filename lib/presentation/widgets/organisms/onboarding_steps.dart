// Atomic Design (Organismo): Secciones funcionales de los pasos del onboarding.
//
// Los cuatro pasos de la rama directa. Ninguno lee signals ni resuelve
// dependencias: reciben la selección actual y avisan por callback. Es lo que
// permite probarlos sueltos y que el issue #12 reutilice las mismas moléculas
// para el cuestionario guía.
//
// Van los cuatro en un archivo porque son variaciones del mismo patrón —una
// lista de opciones— y separarlos daría cuatro archivos de veinte líneas que
// siempre se leen juntos.

import 'package:flutter/material.dart';

import '../../../domain/entities/experience_level.dart';
import '../../../domain/entities/learning_goal.dart';
import '../../../domain/entities/roadmap_track.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../molecules/goal_radio_row.dart';
import '../molecules/option_card_tile.dart';
import '../molecules/track_card.dart';

/// Paso 1: nivel de experiencia. Omitible.
class OnboardingStepRole extends StatelessWidget {
  const OnboardingStepRole({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entrada in etiquetasDeNivel.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: OptionCardTile(
              icon: entrada.value.icon,
              title: entrada.value.label,
              description: entrada.value.description,
              isSelected: selected == entrada.key,
              onTap: () => onSelected(entrada.key),
            ),
          ),
      ],
    );
  }
}

/// Paso 2: especialidad. **No** es omitible: sin track no hay roadmap (CA 1.3).
///
/// Ofrece los 3 tracks decididos más «Aún no lo sé», que no está en ningún
/// mockup y es la opción que deriva al cuestionario guía del issue #12.
class OnboardingStepStack extends StatelessWidget {
  const OnboardingStepStack({
    super.key,
    required this.selected,
    required this.usesGuidedQuiz,
    required this.onSelected,
    required this.onDontKnow,
  });

  final RoadmapTrack? selected;

  /// La usuaria ya eligió «Aún no lo sé»: se marca esa tarjeta.
  final bool usesGuidedQuiz;

  final ValueChanged<RoadmapTrack> onSelected;
  final VoidCallback onDontKnow;

  @override
  Widget build(BuildContext context) {
    final angosto =
        MediaQuery.sizeOf(context).width <= AppConstants.breakpointMobile;
    final columnas = angosto ? 1 : 2;

    final tarjetas = <Widget>[
      for (final entrada in etiquetasDeTrack.entries)
        TrackCard(
          icon: entrada.value.icon,
          title: entrada.value.label,
          description: entrada.value.description,
          isSelected: selected == entrada.key,
          onTap: () => onSelected(entrada.key),
        ),
      TrackCard(
        icon: opcionNoLoSe.icon,
        title: opcionNoLoSe.label,
        description: opcionNoLoSe.description,
        isSelected: usesGuidedQuiz,
        onTap: onDontKnow,
      ),
    ];

    // Filas de altura intrínseca en vez de un GridView: las descripciones de
    // los tracks tienen largos distintos y un `childAspectRatio` fijo las
    // recortaba. Así cada fila mide lo que necesita su tarjeta más alta, y las
    // dos de la fila quedan parejas.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var inicio = 0; inicio < tarjetas.length; inicio += columnas)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var columna = 0; columna < columnas; columna++) ...[
                    if (columna > 0)
                      const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: inicio + columna < tarjetas.length
                          ? tarjetas[inicio + columna]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Paso 3: meta principal. Omitible.
class OnboardingStepGoal extends StatelessWidget {
  const OnboardingStepGoal({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final LearningGoal? selected;
  final ValueChanged<LearningGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entrada in etiquetasDeMeta.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: GoalRadioRow(
              label: entrada.value.label,
              isSelected: selected == entrada.key,
              onTap: () => onSelected(entrada.key),
            ),
          ),
      ],
    );
  }
}

/// Paso 4: resumen. Muestra Nivel y Foco, como el prototipo.
///
/// Los pasos omitidos se muestran como «Sin definir» en vez de esconderse: la
/// usuaria tiene que poder ver qué dejó en blanco.
class OnboardingSummary extends StatelessWidget {
  const OnboardingSummary({
    super.key,
    required this.level,
    required this.track,
    required this.goal,
  });

  final ExperienceLevel? level;
  final RoadmapTrack? track;
  final LearningGoal? goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: AppConstants.iconTileSize * 2,
            height: AppConstants.iconTileSize * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryFixed,
            ),
            child: const Icon(
              Icons.task_alt,
              color: AppColors.primary,
              size: AppConstants.iconTileSize,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          '¡Todo listo!',
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Configuramos tu perfil. Ya podés entrar a tu ruta de aprendizaje.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingLg),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: AppColors.outlineVariant,
              width: AppConstants.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de tu perfil'.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _Fila(etiqueta: 'Nivel', valor: nombreDeNivel(level)),
              _Fila(etiqueta: 'Foco', valor: nombreDeTrack(track)),
              _Fila(etiqueta: 'Meta', valor: nombreDeMeta(goal)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppConstants.iconTileSize + AppConstants.spacingMd,
            child: Text(
              '$etiqueta:',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor ?? 'Sin definir',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valor == null
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
