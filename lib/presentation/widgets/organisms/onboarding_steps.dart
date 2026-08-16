// Atomic Design (Organism): Functional sections of the onboarding steps.
//
// The five steps of the direct branch. None of them reads signals nor resolves
// dependencies: they take the current selection and report back through a
// callback. That is what lets them be tested on their own and what lets issue
// #12 reuse the same molecules for the guided quiz.
//
// They all live in one file because they are variations of the same pattern —a
// list of options— and splitting them would give five twenty-line files that
// are always read together.

import 'package:flutter/material.dart';

import '../../../domain/entities/app_language.dart';
import '../../../domain/entities/experience_level.dart';
import '../../../domain/entities/learning_goal.dart';
import '../../../domain/entities/roadmap_track.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/translate.dart';
import '../atoms/custom_input.dart';
import '../molecules/goal_radio_row.dart';
import '../molecules/option_card_tile.dart';
import '../molecules/track_card.dart';

/// Step 1: interface language. **Not** skippable.
///
/// It is the only step whose text does not go through `tr()`, and it could not:
/// `tr()` picks a language, and picking the language is what this screen is
/// for. Each option is written in the language it offers, which also makes it
/// readable to someone who does not read the other one.
///
/// Nothing is selected on arrival. The profile is born with `language = 'en'`,
/// so showing English pre-selected would present a default as if it were her
/// answer.
class OnboardingStepLanguage extends StatelessWidget {
  const OnboardingStepLanguage({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppLanguage? selected;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in const [
          (AppLanguage.es, 'Español', 'Continuar en español.'),
          (AppLanguage.en, 'English', 'Continue in English.'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: OptionCardTile(
              icon: Icons.translate,
              title: option.$2,
              description: option.$3,
              isSelected: selected == option.$1,
              onTap: () => onSelected(option.$1),
            ),
          ),
      ],
    );
  }
}

/// Step 2: experience level. Skippable.
///
/// The fourth option, "Other", opens a free-text field. It was added after the
/// first beta: the three closed options left anyone who recognized herself in
/// none of them with only two ways out, forcing a wrong answer or skipping the
/// step. It **adds** to the three, it does not replace them.
class OnboardingStepRole extends StatelessWidget {
  const OnboardingStepRole({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.otherText,
    required this.onOtherChanged,
  });

  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel> onSelected;

  /// What she has written in the "Other" field so far.
  final String otherText;
  final ValueChanged<String> onOtherChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in levelLabels.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: OptionCardTile(
              icon: entry.value.icon,
              title: entry.value.label,
              description: entry.value.description,
              isSelected: selected == entry.key,
              onTap: () => onSelected(entry.key),
            ),
          ),
        if (selected == ExperienceLevel.other) ...[
          const SizedBox(height: AppConstants.spacingSm),
          CustomInput(
            hintText: experienceOtherHint,
            // Seeded so coming back to this step shows what she wrote, rather
            // than an empty box next to an option that is clearly marked.
            initialValue: otherText,
            maxLines: 3,
            onChanged: onOtherChanged,
          ),
        ],
      ],
    );
  }
}

/// Step 3: specialty. **Not** skippable: without a track there is no roadmap
/// (AC 1.3).
///
/// It offers the 3 decided tracks plus "I'm not sure yet", which is not in any
/// mockup and is the option that leads to the guided quiz of issue #12.
class OnboardingStepStack extends StatelessWidget {
  const OnboardingStepStack({
    super.key,
    required this.selected,
    required this.usesGuidedQuiz,
    required this.onSelected,
    required this.onDontKnow,
  });

  final RoadmapTrack? selected;

  /// The user already picked "I'm not sure yet": that card is marked.
  final bool usesGuidedQuiz;

  final ValueChanged<RoadmapTrack> onSelected;
  final VoidCallback onDontKnow;

  @override
  Widget build(BuildContext context) {
    final isNarrow =
        MediaQuery.sizeOf(context).width <= AppConstants.breakpointMobile;
    final columns = isNarrow ? 1 : 2;

    final cards = <Widget>[
      for (final entry in trackLabels.entries)
        TrackCard(
          icon: entry.value.icon,
          title: entry.value.label,
          description: entry.value.description,
          isSelected: selected == entry.key,
          onTap: () => onSelected(entry.key),
        ),
      TrackCard(
        icon: notSureOption.icon,
        title: notSureOption.label,
        description: notSureOption.description,
        isSelected: usesGuidedQuiz,
        onTap: onDontKnow,
      ),
    ];

    // Rows of intrinsic height instead of a GridView: the track descriptions
    // have different lengths and a fixed `childAspectRatio` was clipping them.
    // This way each row is as tall as its tallest card, and the two cards in
    // the row match.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var start = 0; start < cards.length; start += columns)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0)
                      const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: start + column < cards.length
                          ? cards[start + column]
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

/// Step 4: main goal. Skippable.
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
        for (final entry in goalLabels.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
            child: GoalRadioRow(
              label: entry.value.label,
              isSelected: selected == entry.key,
              onTap: () => onSelected(entry.key),
            ),
          ),
      ],
    );
  }
}

/// Step 5: summary. Shows Level and Focus, like the prototype.
///
/// Skipped steps show up as "Not set" instead of hiding: the user has to be
/// able to see what she left blank.
class OnboardingSummary extends StatelessWidget {
  const OnboardingSummary({
    super.key,
    required this.level,
    required this.track,
    required this.goal,
    this.experienceOther = '',
  });

  final ExperienceLevel? level;
  final RoadmapTrack? track;
  final LearningGoal? goal;

  /// What she wrote if her level was "Other". The summary shows her own words
  /// back, which say more than the label of the option that opened the field.
  final String experienceOther;

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
          tr("You're all set!", '¡Ya está todo listo!'),
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          tr(
            'Your profile is ready. You can jump into your learning path now.',
            'Tu perfil está listo. Ya puedes empezar tu camino de '
                'aprendizaje.',
          ),
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
                tr('Your profile summary', 'Resumen de tu perfil')
                    .toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _SummaryRow(
                label: tr('Your level', 'Tu nivel'),
                value: level == ExperienceLevel.other &&
                        experienceOther.trim().isNotEmpty
                    ? experienceOther.trim()
                    : levelName(level),
              ),
              _SummaryRow(
                label: tr('Your focus', 'Tu enfoque'),
                value: trackName(track),
              ),
              _SummaryRow(
                label: tr('Your goal', 'Tu meta'),
                value: goalName(goal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String? value;

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
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? tr('Not set', 'Sin definir'),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: value == null
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
