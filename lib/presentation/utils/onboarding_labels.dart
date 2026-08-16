// Presentation layer (Utils): Labels and icons of the onboarding options.
//
// They live here and not in `domain` because the domain layer is pure Dart: it
// cannot import Flutter for an IconData nor fill up with interface text. The
// enums only carry their `slug`, which is what gets persisted.
//
// The texts are the exact ones from the `descubre_tu_ruta_onboarding`
// prototype for the levels and the goals, and from `orientaci_n_de_ruta_test`
// for the tracks, which is the one that brings the descriptions. The two
// vocabularies are aligned on purpose: the step 2 mockup says "Frontend /
// Backend" plainly and the quiz one says "Front-end / Back-end /
// Infrastructure"; having two names for the same track would be confusing.

import 'package:flutter/material.dart';

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import 'translate.dart';

/// Text and icon of an option.
class OptionVisual {
  const OptionVisual({
    required this.label,
    required this.icon,
    this.description,
  });

  final String label;
  final IconData icon;
  final String? description;
}

// `tr()` reads a language signal, so these can no longer be compile-time
// `const` maps: they are getters, rebuilt on every access, so the option
// text always matches the current language when the enclosing `SignalBuilder`
// repaints.
Map<ExperienceLevel, OptionVisual> get levelLabels => {
      ExperienceLevel.student: OptionVisual(
        label: tr('Student / Self-taught', 'Estudiante / Autodidacta'),
        description: tr(
          'I am learning the basics and looking for my first job.',
          'Estoy aprendiendo las bases y buscando mi primer empleo.',
        ),
        icon: Icons.school_outlined,
      ),
      ExperienceLevel.juniorDeveloper: OptionVisual(
        label: tr('Junior Developer', 'Desarrolladora Junior'),
        description: tr(
          'I have less than 2 years of professional experience.',
          'Tengo menos de 2 años de experiencia profesional.',
        ),
        icon: Icons.code,
      ),
      ExperienceLevel.careerSwitcher: OptionVisual(
        label: tr('Career Switcher', 'Cambio de Carrera'),
        description: tr(
          'I come from another field and want to get into tech.',
          'Vengo de otra área y quiero entrar al mundo tech.',
        ),
        icon: Icons.terminal,
      ),
      // Added after the first beta. It does not replace the three above: it
      // gives somewhere to go to whoever recognizes herself in none of them,
      // instead of forcing a wrong answer or a skipped step.
      ExperienceLevel.other: OptionVisual(
        label: tr('Something else', 'Otro motivo'),
        description: tr(
          'None of these fit me. I will tell you in my own words.',
          'Ninguna de estas me describe. Te cuento en mis palabras.',
        ),
        icon: Icons.edit_outlined,
      ),
    };

/// Placeholder of the free-text field the "Other" option opens.
String get experienceOtherHint => tr(
      'What brings you to Kora?',
      '¿Qué te trae a Kora?',
    );

Map<RoadmapTrack, OptionVisual> get trackLabels => {
      RoadmapTrack.frontend: OptionVisual(
        label: tr('Front-end', 'Front-end'),
        description: tr(
          'Build the screens and buttons people see and tap — the '
              'part that makes a great first impression.',
          'Crea las pantallas y botones que la gente ve y toca: la '
              'parte que da la primera gran impresión.',
        ),
        icon: Icons.brush_outlined,
      ),
      RoadmapTrack.backend: OptionVisual(
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
      RoadmapTrack.infrastructure: OptionVisual(
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
      RoadmapTrack.uiux: OptionVisual(
        label: tr('UI/UX Design', 'Diseño UI/UX'),
        description: tr(
          'Understand people and design the screens they will love — '
              'from the first sketch to the final look and feel.',
          'Comprende a las personas y diseña las pantallas que van a '
              'amar, desde el primer boceto hasta el look final.',
        ),
        icon: Icons.palette_outlined,
      ),
      RoadmapTrack.projectManagement: OptionVisual(
        label: tr('Project Management', 'Gestión de Proyectos'),
        description: tr(
          'Guide teams and projects from idea to delivery — plan the '
              'work, manage risks and keep everyone moving together.',
          'Guía equipos y proyectos desde la idea hasta la entrega: '
              'planifica el trabajo, gestiona riesgos y mantén a todos '
              'avanzando juntos.',
        ),
        icon: Icons.fact_check_outlined,
      ),
    };

Map<LearningGoal, OptionVisual> get goalLabels => {
      LearningGoal.firstJob: OptionVisual(
        label: tr(
          'Land my first professional job',
          'Conseguir mi primer empleo profesional',
        ),
        icon: Icons.work_outline,
      ),
      LearningGoal.newLanguage: OptionVisual(
        label: tr(
          'Learn a new programming language',
          'Aprender un nuevo lenguaje de programación',
        ),
        icon: Icons.translate,
      ),
      LearningGoal.interviewSkills: OptionVisual(
        label: tr(
          'Get better at technical interviews',
          'Mejorar en entrevistas técnicas',
        ),
        icon: Icons.record_voice_over_outlined,
      ),
      LearningGoal.middleLevel: OptionVisual(
        label: tr(
          'Move up to a Middle-level role',
          'Avanzar a un puesto de nivel Middle',
        ),
        icon: Icons.trending_up,
      ),
    };

/// The fourth option of step 2, which is in no mockup: it is the one that
/// connects the two prototype designs and leads to the guided quiz (issue
/// #12).
OptionVisual get notSureOption => OptionVisual(
      label: tr("I'm not sure yet", 'Todavía no estoy segura'),
      description: tr(
        'We ask you a few questions and suggest a path.',
        'Te hacemos algunas preguntas y te sugerimos un camino.',
      ),
      icon: Icons.help_outline,
    );

/// Track name for the summary. `null` when nothing has been chosen yet.
String? trackName(RoadmapTrack? track) =>
    track == null ? null : trackLabels[track]!.label;

/// Level name for the summary.
String? levelName(ExperienceLevel? level) =>
    level == null ? null : levelLabels[level]!.label;

/// Goal name for the summary.
String? goalName(LearningGoal? goal) =>
    goal == null ? null : goalLabels[goal]!.label;
