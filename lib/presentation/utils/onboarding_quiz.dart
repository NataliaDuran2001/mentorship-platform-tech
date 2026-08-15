// Presentation layer (Utils): The set of questions of the guided quiz.
//
// Each option declares which track it leans towards (`affinity`). That is the
// only thing the quiz contributes to the decision: counting the votes and
// breaking ties belongs to `RecommendTrackUseCase` (domain layer), not here
// and much less to a widget.
//
// The first question is the one from the `orientaci_n_de_ruta_test` prototype,
// with its exact texts. The other two are defined here, as the scope of issue
// #12 asks. There are three and not one so that the recommendation does not
// hang on a single click: with a single question the quiz would be a track
// picker in disguise, and with many it would turn into paperwork. Three also
// allows real ties, which is the case the tie-break of #8 has to resolve.

import 'package:flutter/material.dart';

import '../../domain/entities/roadmap_track.dart';
import 'translate.dart';

class QuizOption {
  const QuizOption({
    required this.affinity,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Track this option adds a vote to.
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

  /// Starts at 1. It is what forms the `quiz_1`, `quiz_2`, … key the answer is
  /// persisted with.
  final int number;

  final String prompt;
  final String subtitle;
  final List<QuizOption> options;
}

/// The questions, in order.
///
/// A getter and not a `const` list: `tr()` reads the language signal, so the
/// text must be recomputed on every access instead of being fixed once at
/// load time.
List<QuizQuestion> get quizQuestions => [
      QuizQuestion(
        number: 1,
        prompt: tr(
          'What kind of problems do you enjoy solving the most?',
          '¿Qué tipo de problemas disfrutas más resolver?',
        ),
        subtitle: tr(
          'Your answer helps us find the learning path that fits you '
              'best.',
          'Tu respuesta nos ayuda a encontrar el camino de aprendizaje '
              'que mejor te queda.',
        ),
        options: [
          QuizOption(
            affinity: RoadmapTrack.frontend,
            label: tr('Front-end', 'Front-end'),
            description: tr(
              'Build the screens and buttons people see and tap — the '
                  'part that makes a great first impression.',
              'Crea las pantallas y botones que la gente ve y toca: la '
                  'parte que da la primera gran impresión.',
            ),
            icon: Icons.brush_outlined,
          ),
          QuizOption(
            affinity: RoadmapTrack.backend,
            label: tr('Back-end', 'Back-end'),
            description: tr(
              'Build the logic that works behind the scenes and store '
                  'information so everything keeps working as more people use it.',
              'Crea la lógica que funciona detrás de escena y almacena '
                  'información para que todo siga funcionando cuando más '
                  'personas lo usen.',
            ),
            icon: Icons.storage_outlined,
          ),
          QuizOption(
            affinity: RoadmapTrack.infrastructure,
            label: tr('Infrastructure & DevOps', 'Infraestructura y DevOps'),
            description: tr(
              'Set up the tools that keep everything running smoothly '
                  'and help apps reach more people without breaking.',
              'Configura las herramientas que mantienen todo funcionando '
                  'sin problemas y ayudan a que las apps lleguen a más '
                  'personas sin fallar.',
            ),
            icon: Icons.settings_suggest_outlined,
          ),
        ],
      ),
      QuizQuestion(
        number: 2,
        prompt: tr(
          'Which part of a project is easiest for you to picture?',
          '¿Qué parte de un proyecto te es más fácil imaginar?',
        ),
        subtitle: tr(
          'There is no right answer: pick the one that comes to mind '
              'first.',
          'No hay una respuesta correcta: elige la que se te venga a '
              'la mente primero.',
        ),
        options: [
          QuizOption(
            affinity: RoadmapTrack.frontend,
            label: tr(
              'How it looks and how it is used',
              'Cómo se ve y cómo se usa',
            ),
            description: tr(
              'The screens, the colors, what happens when you tap '
                  'something.',
              'Las pantallas, los colores, qué pasa cuando tocas algo.',
            ),
            icon: Icons.palette_outlined,
          ),
          QuizOption(
            affinity: RoadmapTrack.backend,
            label: tr('How the data is stored', 'Cómo se guardan los datos'),
            description: tr(
              'What information is needed and how it all connects.',
              'Qué información se necesita y cómo se conecta todo.',
            ),
            icon: Icons.account_tree_outlined,
          ),
          QuizOption(
            affinity: RoadmapTrack.infrastructure,
            label: tr('How it reaches people', 'Cómo llega a las personas'),
            description: tr(
              'Where it lives, how it ships and what happens if it '
                  'goes down.',
              'Dónde vive, cómo se despliega y qué pasa si se cae.',
            ),
            icon: Icons.rocket_launch_outlined,
          ),
        ],
      ),
      QuizQuestion(
        number: 3,
        prompt: tr(
          'When something breaks, what do you most enjoy fixing?',
          'Cuando algo se rompe, ¿qué es lo que más disfrutas arreglar?',
        ),
        subtitle: tr(
          'Think of the last time you got stuck on something and pulled '
              'it through.',
          'Piensa en la última vez que te atoraste con algo y lo '
              'lograste resolver.',
        ),
        options: [
          QuizOption(
            affinity: RoadmapTrack.frontend,
            label: tr(
              'Something looks off or does not respond',
              'Algo se ve mal o no responde',
            ),
            description: tr(
              'A button that does nothing, a text that overflows.',
              'Un botón que no hace nada, un texto que se desborda.',
            ),
            icon: Icons.smartphone_outlined,
          ),
          QuizOption(
            affinity: RoadmapTrack.backend,
            label: tr(
              'A calculation comes out wrong',
              'Un cálculo sale mal',
            ),
            description: tr(
              'A total that does not add up, a piece of data that '
                  'goes missing.',
              'Un total que no cuadra, un dato que desaparece.',
            ),
            icon: Icons.functions,
          ),
          QuizOption(
            affinity: RoadmapTrack.infrastructure,
            label: tr('Something is slow or down', 'Algo va lento o se cae'),
            description: tr(
              'The system works, but it lags or goes down every now '
                  'and then.',
              'El sistema funciona, pero se traba o se cae de vez en '
                  'cuando.',
            ),
            icon: Icons.speed_outlined,
          ),
        ],
      ),
    ];

/// Rationale for the recommended track, for the result screen. It is UI text,
/// so it lives in this layer.
Map<RoadmapTrack, String> get recommendationRationale => {
      RoadmapTrack.frontend: tr(
        'Your answers point to what people see and touch: '
            'screens, how things feel to use, and the little visual details.',
        'Tus respuestas apuntan a lo que la gente ve y toca: '
            'pantallas, cómo se sienten al usarlas y los pequeños '
            'detalles visuales.',
      ),
      RoadmapTrack.backend: tr(
        'Your answers point to logic and information: how '
            'data is organized and how everything keeps working smoothly.',
        'Tus respuestas apuntan a la lógica y la información: cómo '
            'se organizan los datos y cómo todo sigue funcionando bien.',
      ),
      RoadmapTrack.infrastructure: tr(
        'Your answers point to keeping things '
            'running: automating tasks, launching updates, and keeping systems '
            'healthy.',
        'Tus respuestas apuntan a mantener todo funcionando: '
            'automatizar tareas, lanzar actualizaciones y mantener los '
            'sistemas saludables.',
      ),
    };
