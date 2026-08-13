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
const List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    number: 1,
    prompt: 'What kind of problems do you enjoy solving the most?',
    subtitle: 'Your answer helps us find the learning path that fits you '
        'best.',
    options: [
      QuizOption(
        affinity: RoadmapTrack.frontend,
        label: 'Front-end',
        description: 'Build the screens and buttons people see and tap — the '
            'part that makes a great first impression.',
        icon: Icons.brush_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.backend,
        label: 'Back-end',
        description: 'Build the logic that works behind the scenes and store '
            'information so everything keeps working as more people use it.',
        icon: Icons.storage_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.infrastructure,
        label: 'Infrastructure',
        description: 'Set up the tools that keep everything running smoothly '
            'and help apps reach more people without breaking.',
        icon: Icons.settings_suggest_outlined,
      ),
    ],
  ),
  QuizQuestion(
    number: 2,
    prompt: 'Which part of a project is easiest for you to picture?',
    subtitle: 'There is no right answer: pick the one that comes to mind '
        'first.',
    options: [
      QuizOption(
        affinity: RoadmapTrack.frontend,
        label: 'How it looks and how it is used',
        description: 'The screens, the colors, what happens when you tap '
            'something.',
        icon: Icons.palette_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.backend,
        label: 'How the data is stored',
        description: 'What information is needed and how it all connects.',
        icon: Icons.account_tree_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.infrastructure,
        label: 'How it reaches people',
        description: 'Where it lives, how it ships and what happens if it '
            'goes down.',
        icon: Icons.rocket_launch_outlined,
      ),
    ],
  ),
  QuizQuestion(
    number: 3,
    prompt: 'When something breaks, what do you most enjoy fixing?',
    subtitle: 'Think of the last time you got stuck on something and pulled '
        'it through.',
    options: [
      QuizOption(
        affinity: RoadmapTrack.frontend,
        label: 'Something looks off or does not respond',
        description: 'A button that does nothing, a text that overflows.',
        icon: Icons.smartphone_outlined,
      ),
      QuizOption(
        affinity: RoadmapTrack.backend,
        label: 'A calculation comes out wrong',
        description: 'A total that does not add up, a piece of data that '
            'goes missing.',
        icon: Icons.functions,
      ),
      QuizOption(
        affinity: RoadmapTrack.infrastructure,
        label: 'Something is slow or down',
        description: 'The system works, but it lags or goes down every now '
            'and then.',
        icon: Icons.speed_outlined,
      ),
    ],
  ),
];

/// Rationale for the recommended track, for the result screen. It is UI text,
/// so it lives in this layer.
const Map<RoadmapTrack, String> recommendationRationale = {
  RoadmapTrack.frontend: 'Your answers point to what people see and touch: '
      'screens, how things feel to use, and the little visual details.',
  RoadmapTrack.backend: 'Your answers point to logic and information: how '
      'data is organized and how everything keeps working smoothly.',
  RoadmapTrack.infrastructure: 'Your answers point to keeping things '
      'running: automating tasks, launching updates, and keeping systems '
      'healthy.',
};
