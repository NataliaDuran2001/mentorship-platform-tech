// Atomic Design (Organism): Functional sections of the onboarding steps.
//
// The four steps of the direct branch. None of them reads signals nor resolves
// dependencies: they take the current selection and report back through a
// callback. That is what lets them be tested on their own and what lets issue
// #12 reuse the same molecules for the guided quiz.
//
// All four live in one file because they are variations of the same pattern —a
// list of options— and splitting them would give four twenty-line files that
// are always read together.

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

/// Step 1: experience level. Skippable.
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
      ],
    );
  }
}

/// Step 2: specialty. **Not** skippable: without a track there is no roadmap
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

/// Step 3: main goal. Skippable.
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

/// Step 4: summary. Shows Level and Focus, like the prototype.
///
/// Skipped steps show up as "Not set" instead of hiding: the user has to be
/// able to see what she left blank.
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
          "You're all set!",
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Your profile is ready. You can jump into your learning path now.',
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
                'Your profile summary'.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _SummaryRow(label: 'Level', value: levelName(level)),
              _SummaryRow(label: 'Focus', value: trackName(track)),
              _SummaryRow(label: 'Goal', value: goalName(goal)),
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
              value ?? 'Not set',
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
