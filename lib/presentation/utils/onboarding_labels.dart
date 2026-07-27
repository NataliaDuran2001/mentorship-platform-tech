// Capa Presentation (Utils): Etiquetas en español e íconos de las opciones del
// onboarding.
//
// Viven acá y no en `domain` porque la capa de dominio es Dart puro: no puede
// importar Flutter para un IconData ni cargarse de texto de interfaz. Los enums
// solo llevan su `slug`, que es lo que se persiste.
//
// Los textos son los exactos del prototipo `descubre_tu_ruta_onboarding` para
// los niveles y las metas, y los de `orientaci_n_de_ruta_test` para los tracks,
// que es el que trae las descripciones. Se alinean los dos vocabularios a
// propósito: el mockup del paso 2 dice «Frontend / Backend» a secas y el del
// cuestionario dice «Front-end / Back-end / Infraestructura»; tener dos nombres
// para el mismo track sería confuso.

import 'package:flutter/material.dart';

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';

/// Texto y ícono de una opción.
class OpcionVisual {
  const OpcionVisual({
    required this.label,
    required this.icon,
    this.description,
  });

  final String label;
  final IconData icon;
  final String? description;
}

const Map<ExperienceLevel, OpcionVisual> etiquetasDeNivel = {
  ExperienceLevel.student: OpcionVisual(
    label: 'Estudiante / Autodidacta',
    description: 'Estoy aprendiendo las bases y busco mi primer empleo.',
    icon: Icons.school_outlined,
  ),
  ExperienceLevel.juniorDeveloper: OpcionVisual(
    label: 'Junior Developer',
    description: 'Tengo menos de 2 años de experiencia profesional.',
    icon: Icons.code,
  ),
  ExperienceLevel.careerSwitcher: OpcionVisual(
    label: 'Cambiando de Carrera',
    description: 'Vengo de otro sector y quiero entrar a tech.',
    icon: Icons.terminal,
  ),
};

const Map<RoadmapTrack, OpcionVisual> etiquetasDeTrack = {
  RoadmapTrack.frontend: OpcionVisual(
    label: 'Front-end',
    description: 'Crear interfaces visuales y experiencias de usuario que '
        'cautiven a primera vista.',
    icon: Icons.brush_outlined,
  ),
  RoadmapTrack.backend: OpcionVisual(
    label: 'Back-end',
    description: 'Diseñar la lógica detrás de escena y bases de datos robustas '
        'para escalar sistemas.',
    icon: Icons.storage_outlined,
  ),
  RoadmapTrack.infrastructure: OpcionVisual(
    label: 'Infraestructura',
    description: 'Organizar procesos, automatizar tareas y optimizar flujos de '
        'trabajo masivos.',
    icon: Icons.settings_suggest_outlined,
  ),
};

const Map<LearningGoal, OpcionVisual> etiquetasDeMeta = {
  LearningGoal.firstJob: OpcionVisual(
    label: 'Conseguir mi primer empleo profesional',
    icon: Icons.work_outline,
  ),
  LearningGoal.newLanguage: OpcionVisual(
    label: 'Aprender un nuevo lenguaje de programación',
    icon: Icons.translate,
  ),
  LearningGoal.interviewSkills: OpcionVisual(
    label: 'Mejorar mis habilidades de entrevista técnica',
    icon: Icons.record_voice_over_outlined,
  ),
  LearningGoal.middleLevel: OpcionVisual(
    label: 'Escalar a un puesto de nivel Middle',
    icon: Icons.trending_up,
  ),
};

/// La cuarta opción del paso 2, que no está en ningún mockup: es la que conecta
/// los dos diseños del prototipo y deriva al cuestionario guía (issue #12).
const OpcionVisual opcionNoLoSe = OpcionVisual(
  label: 'Aún no lo sé',
  description: 'Te hacemos unas preguntas y te sugerimos una ruta.',
  icon: Icons.help_outline,
);

/// Nombre del track para el resumen. `null` cuando todavía no se eligió.
String? nombreDeTrack(RoadmapTrack? track) =>
    track == null ? null : etiquetasDeTrack[track]!.label;

/// Nombre del nivel para el resumen.
String? nombreDeNivel(ExperienceLevel? nivel) =>
    nivel == null ? null : etiquetasDeNivel[nivel]!.label;

/// Nombre de la meta para el resumen.
String? nombreDeMeta(LearningGoal? meta) =>
    meta == null ? null : etiquetasDeMeta[meta]!.label;
