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

const Map<ExperienceLevel, OptionVisual> levelLabels = {
  ExperienceLevel.student: OptionVisual(
    label: 'Student / Self-taught',
    description: 'I am learning the basics and looking for my first job.',
    icon: Icons.school_outlined,
  ),
  ExperienceLevel.juniorDeveloper: OptionVisual(
    label: 'Junior Developer',
    description: 'I have less than 2 years of professional experience.',
    icon: Icons.code,
  ),
  ExperienceLevel.careerSwitcher: OptionVisual(
    label: 'Career Switcher',
    description: 'I come from another field and want to get into tech.',
    icon: Icons.terminal,
  ),
};

const Map<RoadmapTrack, OptionVisual> trackLabels = {
  RoadmapTrack.frontend: OptionVisual(
    label: 'Front-end',
    description: 'Build visual interfaces and user experiences that win '
        'people over at first sight.',
    icon: Icons.brush_outlined,
  ),
  RoadmapTrack.backend: OptionVisual(
    label: 'Back-end',
    description: 'Design the logic behind the scenes and solid databases to '
        'scale systems.',
    icon: Icons.storage_outlined,
  ),
  RoadmapTrack.infrastructure: OptionVisual(
    label: 'Infrastructure',
    description: 'Organize processes, automate tasks and smooth out huge '
        'workflows.',
    icon: Icons.settings_suggest_outlined,
  ),
};

const Map<LearningGoal, OptionVisual> goalLabels = {
  LearningGoal.firstJob: OptionVisual(
    label: 'Land my first professional job',
    icon: Icons.work_outline,
  ),
  LearningGoal.newLanguage: OptionVisual(
    label: 'Learn a new programming language',
    icon: Icons.translate,
  ),
  LearningGoal.interviewSkills: OptionVisual(
    label: 'Get better at technical interviews',
    icon: Icons.record_voice_over_outlined,
  ),
  LearningGoal.middleLevel: OptionVisual(
    label: 'Move up to a Middle-level role',
    icon: Icons.trending_up,
  ),
};

/// The fourth option of step 2, which is in no mockup: it is the one that
/// connects the two prototype designs and leads to the guided quiz (issue
/// #12).
const OptionVisual notSureOption = OptionVisual(
  label: "I'm not sure yet",
  description: 'We ask you a few questions and suggest a path.',
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
