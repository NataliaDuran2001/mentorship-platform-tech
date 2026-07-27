// Capa Presentation (Utils): El set de preguntas del cuestionario guía.
//
// Cada opción declara a qué track tira (`affinity`). Eso es lo único que el
// cuestionario aporta a la decisión: contar los votos y resolver empates es de
// `RecommendTrackUseCase` (capa domain), no de acá y mucho menos de un widget.
//
// La primera pregunta es la del prototipo `orientaci_n_de_ruta_test`, con sus
// textos exactos. Las otras dos se definen acá, como pide el alcance del issue
// #12. Son tres y no una para que la recomendación no dependa de un solo clic:
// con una sola pregunta el cuestionario sería un selector de track disfrazado, y
// con muchas se volvería un trámite. Tres permite además que haya empates
// reales, que es el caso que el desempate del #8 tiene que resolver.

import 'package:flutter/material.dart';

import '../../domain/entities/roadmap_track.dart';

class QuizOption {
  const QuizOption({
    required this.affinity,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Track al que suma un voto esta opción.
  final RoadmapTrack affinity;

  final String label;
  final String description;
  final IconData icon;
}

class QuizQuestion {
  const QuizQuestion({
    required this.number,
    required this.prompt,
    required this.subtitle,
    required this.options,
  });

  /// Empieza en 1. Es lo que forma la clave `quiz_1`, `quiz_2`, … con la que se
  /// persiste la respuesta.
  final int number;

  final String prompt;
  final String subtitle;
  final List<QuizOption> options;
}

/// Las preguntas, en orden.
const List<QuizQuestion> preguntasDelCuestionario = [
  QuizQuestion(
    number: 1,
    prompt: '¿Qué tipo de problemas te entusiasma más resolver?',
    subtitle: 'Tu respuesta nos ayuda a trazar tu ruta de aprendizaje ideal '
        'hacia el dominio técnico.',
    options: [
      QuizOption(
        affinity: RoadmapTrack.frontend,
        label: 'Front-end',
        description: 'Crear interfaces visuales y experiencias de usuario que '
            'cautiven a primera vista.',
        icon: Icons.brush_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.backend,
        label: 'Back-end',
        description: 'Diseñar la lógica detrás de escena y bases de datos '
            'robustas para escalar sistemas.',
        icon: Icons.storage_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.infrastructure,
        label: 'Infraestructura',
        description: 'Organizar procesos, automatizar tareas y optimizar flujos '
            'de trabajo masivos.',
        icon: Icons.settings_suggest_outlined,
      ),
    ],
  ),
  QuizQuestion(
    number: 2,
    prompt: '¿Qué parte de un proyecto te resulta más fácil de imaginar?',
    subtitle: 'No hay respuesta correcta: elegí la que se te venga primero a '
        'la cabeza.',
    options: [
      QuizOption(
        affinity: RoadmapTrack.frontend,
        label: 'Cómo se ve y cómo se usa',
        description: 'Las pantallas, los colores, qué pasa al tocar cada cosa.',
        icon: Icons.palette_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.backend,
        label: 'Cómo se guardan los datos',
        description: 'Qué información hace falta y cómo se relaciona entre sí.',
        icon: Icons.account_tree_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.infrastructure,
        label: 'Cómo llega a la gente',
        description: 'Dónde vive, cómo se publica y qué pasa si se cae.',
        icon: Icons.rocket_launch_outlined,
      ),
    ],
  ),
  QuizQuestion(
    number: 3,
    prompt: 'Cuando algo no funciona, ¿qué te da más satisfacción resolver?',
    subtitle: 'Pensá en la última vez que te trabaste con algo y lo sacaste '
        'adelante.',
    options: [
      QuizOption(
        affinity: RoadmapTrack.frontend,
        label: 'Que algo se vea mal o no responda',
        description: 'Un botón que no reacciona, un texto que se desborda.',
        icon: Icons.smartphone_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.backend,
        label: 'Que un cálculo dé mal',
        description: 'Un total que no cierra, un dato que se pierde.',
        icon: Icons.functions,
      ),
      QuizOption(
        affinity: RoadmapTrack.infrastructure,
        label: 'Que algo esté lento o caído',
        description: 'El sistema anda, pero tarda o se cae cada tanto.',
        icon: Icons.speed_outlined,
      ),
    ],
  ),
];

/// Justificación en español del track recomendado, para la pantalla de
/// resultado. Es texto de UI, así que vive en esta capa.
const Map<RoadmapTrack, String> justificacionDeRecomendacion = {
  RoadmapTrack.frontend: 'Tus respuestas apuntan a lo que la gente ve y toca: '
      'interfaces, experiencia de uso y detalle visual.',
  RoadmapTrack.backend: 'Tus respuestas apuntan a la lógica y los datos: cómo '
      'se organiza la información y cómo se sostiene un sistema.',
  RoadmapTrack.infrastructure: 'Tus respuestas apuntan a que las cosas '
      'funcionen y escalen: automatización, despliegue y operación.',
};
