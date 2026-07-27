// Atomic Design (Organismo): Sección funcional reutilizable.
// El cuestionario guía: una pregunta con sus opciones, y la pantalla de
// resultado con la recomendación.
//
// Reutiliza TrackCard del issue #10, igual que el paso 2 del flujo directo, así
// que las dos ramas se ven como la misma aplicación.
//
// **No contiene la regla de decisión.** Recibe la recomendación ya calculada por
// `RecommendTrackUseCase` y solo la muestra. Si acá hubiera un `if` sobre las
// respuestas, ese sería exactamente el error que el AC3 del issue #12 busca.

import 'package:flutter/material.dart';

import '../../../domain/entities/roadmap_track.dart';
import '../../../domain/entities/track_recommendation.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/onboarding_quiz.dart';
import '../molecules/track_card.dart';

/// Una pregunta del cuestionario con sus tres opciones.
class GuidedQuizStep extends StatelessWidget {
  const GuidedQuizStep({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  final QuizQuestion question;

  /// Track votado en esta pregunta, si ya se respondió.
  final RoadmapTrack? selected;

  final ValueChanged<RoadmapTrack> onSelected;

  @override
  Widget build(BuildContext context) {
    final angosto =
        MediaQuery.sizeOf(context).width <= AppConstants.breakpointMobile;
    final columnas = angosto ? 1 : question.options.length;

    // Misma técnica que el paso 2: filas de altura intrínseca en vez de un
    // GridView, porque las descripciones tienen largos distintos.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var inicio = 0;
            inicio < question.options.length;
            inicio += columnas)
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
                      child: inicio + columna < question.options.length
                          ? _opcion(question.options[inicio + columna])
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

  Widget _opcion(QuizOption opcion) {
    return TrackCard(
      icon: opcion.icon,
      title: opcion.label,
      description: opcion.description,
      isSelected: selected == opcion.affinity,
      onTap: () => onSelected(opcion.affinity),
    );
  }
}

/// Pantalla de resultado: la recomendación, su justificación y la confirmación.
///
/// La confirmación es explícita a propósito: la recomendación es una sugerencia,
/// no una asignación. Y si el resultado salió de un empate, se dice, en vez de
/// presentarlo como concluyente.
class GuidedQuizResult extends StatelessWidget {
  const GuidedQuizResult({
    super.key,
    required this.recommendation,
    required this.onConfirm,
    required this.onOverride,
    required this.onRedo,
  });

  final TrackRecommendation recommendation;
  final VoidCallback onConfirm;
  final ValueChanged<RoadmapTrack> onOverride;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final track = recommendation.track;

    if (track == null) {
      // Sin respuestas utilizables no hay nada que recomendar. Puede pasar si se
      // reanuda un cuestionario vacío.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Todavía no tenemos suficientes respuestas para sugerirte una ruta.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRedo,
              child: const Text('Responder el cuestionario'),
            ),
          ),
        ],
      );
    }

    final etiqueta = etiquetasDeTrack[track]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Te sugerimos esta ruta',
          style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        // La tarjeta va marcada como seleccionada, pero el track todavía NO se
        // asignó: se asigna al confirmar.
        TrackCard(
          icon: etiqueta.icon,
          title: etiqueta.label,
          description: justificacionDeRecomendacion[track],
          isSelected: true,
          onTap: onConfirm,
        ),
        if (recommendation.wasTie) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Estuvo parejo con otra ruta, así que revisá la sugerencia antes de '
            'confirmarla.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          '¿Preferís otra?',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        // Corrección manual: la usuaria puede ignorar la sugerencia.
        Wrap(
          spacing: AppConstants.spacingSm,
          runSpacing: AppConstants.spacingSm,
          children: [
            for (final otro in RoadmapTrack.values)
              if (otro != track)
                OutlinedButton.icon(
                  onPressed: () => onOverride(otro),
                  icon: Icon(etiquetasDeTrack[otro]!.icon),
                  label: Text(etiquetasDeTrack[otro]!.label),
                ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRedo,
            child: const Text('Volver a responder el cuestionario'),
          ),
        ),
      ],
    );
  }
}
