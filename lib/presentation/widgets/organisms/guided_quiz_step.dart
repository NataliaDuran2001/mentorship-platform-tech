// Atomic Design (Organism): Reusable functional section.
// The guided quiz: one question with its options, and the result screen with
// the recommendation.
//
// It reuses TrackCard from issue #10, same as step 2 of the direct flow, so
// that both branches look like the same application.
//
// **It does not hold the decision rule.** It takes the recommendation already
// computed by `RecommendTrackUseCase` and only displays it. An `if` over the
// answers in here would be exactly the mistake that AC3 of issue #12 looks for.

import 'package:flutter/material.dart';

import '../../../domain/entities/roadmap_track.dart';
import '../../../domain/entities/track_recommendation.dart';
import '../../state/onboarding_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/onboarding_quiz.dart';
import '../molecules/track_card.dart';

/// One quiz question with its three options.
class GuidedQuizStep extends StatelessWidget {
  const GuidedQuizStep({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  final QuizQuestion question;

  /// Track voted in this question, if it was already answered.
  final RoadmapTrack? selected;

  final ValueChanged<RoadmapTrack> onSelected;

  @override
  Widget build(BuildContext context) {
    final isNarrow =
        MediaQuery.sizeOf(context).width <= AppConstants.breakpointMobile;
    final columns = isNarrow ? 1 : question.options.length;

    // Same technique as step 2: rows of intrinsic height instead of a
    // GridView, because the descriptions have different lengths.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var start = 0;
            start < question.options.length;
            start += columns)
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
                      child: start + column < question.options.length
                          ? _option(question.options[start + column])
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

  Widget _option(QuizOption option) {
    return TrackCard(
      icon: option.icon,
      title: option.label,
      description: option.description,
      isSelected: selected == option.affinity,
      onTap: () => onSelected(option.affinity),
    );
  }
}

/// Result screen: the recommendation, why it came up and the confirmation.
///
/// The confirmation is explicit on purpose: the recommendation is a
/// suggestion, not an assignment. And if the result came out of a tie, that is
/// said, instead of presenting it as conclusive.
///
/// AI-First: When `recommendation.isAiGenerated` is true, the card shows
/// Kimi3's natural-language reasoning instead of a generic label.
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

    // AI is still computing: show a spinner with a friendly message.
    if (quizAnalyzing.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            '✨ Analyzing your profile with AI…',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (track == null) {
      // With no usable answers there is nothing to recommend. It can happen if
      // an empty quiz is resumed.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "We don't have enough answers yet to suggest a path for you.",
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRedo,
              child: const Text('Take the quiz'),
            ),
          ),
        ],
      );
    }

    final label = trackLabels[track]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI badge or generic label
        if (recommendation.isAiGenerated)
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'AI-Powered Analysis',
                style: textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
          )
        else
          Text(
            'We suggest this path',
            style: textTheme.labelMedium
                ?.copyWith(color: AppColors.primary),
          ),
        const SizedBox(height: AppConstants.spacingSm),
        // The card is marked as selected, but the track is NOT assigned yet:
        // it gets assigned on confirm.
        TrackCard(
          icon: label.icon,
          title: label.label,
          description: recommendation.isAiGenerated
              ? recommendation.reasoning
              : recommendationRationale[track],
          isSelected: true,
          onTap: onConfirm,
        ),
        if (recommendation.wasTie && !recommendation.isAiGenerated) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'It was close with another path, so take a look at the suggestion '
            'before you confirm it.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        // AI alternatives block
        if (recommendation.isAiGenerated &&
            recommendation.alternatives.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Also worth considering:',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          for (final alt in recommendation.alternatives)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppConstants.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(trackLabels[alt.track]!.icon,
                      size: 16,
                      color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      '${trackLabels[alt.track]!.label}: ${alt.reason}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          'Prefer another one?',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        // Manual override: you can ignore the suggestion.
        Wrap(
          spacing: AppConstants.spacingSm,
          runSpacing: AppConstants.spacingSm,
          children: [
            for (final other in RoadmapTrack.values)
              if (other != track)
                OutlinedButton.icon(
                  onPressed: () => onOverride(other),
                  icon: Icon(trackLabels[other]!.icon),
                  label: Text(trackLabels[other]!.label),
                ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRedo,
            child: const Text('Take the quiz again'),
          ),
        ),
      ],
    );
  }
}
