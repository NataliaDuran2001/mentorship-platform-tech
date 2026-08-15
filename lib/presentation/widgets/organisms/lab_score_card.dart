// Atomic Design (Organism): The result of a finished lab — how many were
// answered right on the first try, the tier that lands in, and what is worth
// going back to. Context-free: takes the score and the missed questions, reads
// no signals.
//
// The score shows as a fraction rather than the circular percentage gauge the
// interview results use. Those are an AI's 0-100 reading of an open answer,
// where a percentage is the only honest shape. Here the number is a count of
// discrete challenges, and "4 of 5" is what the learner actually did.

import 'package:flutter/material.dart';

import '../../../domain/entities/lab_score.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/lab_score_bands.dart';

class LabScoreCard extends StatelessWidget {
  const LabScoreCard({
    super.key,
    required this.score,
    this.missedQuestions = const <String>[],
  });

  final LabScore score;

  /// The questions that took more than one try, named so the learner knows
  /// what to go back to instead of replaying the whole section blind.
  final List<String> missedQuestions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = labScoreBandStyle(score.band);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ScoreFraction(score: score, color: style.color),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'answered right on the first try',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _BandBadge(style: style),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            style.headline,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (missedQuestions.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingLg),
            _MissedList(questions: missedQuestions),
          ],
        ],
      ),
    );
  }
}

class _ScoreFraction extends StatelessWidget {
  const _ScoreFraction({required this.score, required this.color});

  final LabScore score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${score.correct}',
          style: textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          ' / ${score.total}',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BandBadge extends StatelessWidget {
  const _BandBadge({required this.style});

  final LabScoreBandStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: style.containerColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: style.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MissedList extends StatelessWidget {
  const _MissedList({required this.questions});

  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worth another look',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          for (final question in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.refresh,
                    size: AppConstants.iconSizeSm,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      question,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
