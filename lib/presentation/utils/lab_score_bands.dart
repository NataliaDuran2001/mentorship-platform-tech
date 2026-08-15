// Presentation layer (Util): Renders a LabScoreBand as a label, a headline and
// a color pair, so the screen that closes a lab never shows a bare "4 / 5".
// Mirrors interview_score_bands.dart, and like it uses only existing AppColors
// tokens — no new colors for this feature.
//
// The weakest band is deliberately NOT red. Reaching this screen at all means
// the section was finished: every challenge was eventually answered right.
// Error red would read as a failed lab, which is not what happened. Neutral
// carries "come back to this" without taking away what was just done, and the
// copy does the rest.

import 'package:flutter/material.dart';

import '../../domain/entities/lab_score.dart';
import 'app_colors.dart';

class LabScoreBandStyle {
  const LabScoreBandStyle({
    required this.label,
    required this.headline,
    required this.color,
    required this.containerColor,
  });

  /// Short read on the run, e.g. "Perfect run". Goes in the badge.
  final String label;

  /// The sentence that congratulates or encourages, right under the score.
  final String headline;

  /// Foreground color for text and icons on top of [containerColor].
  final Color color;

  /// Background color for the badge.
  final Color containerColor;
}

LabScoreBandStyle labScoreBandStyle(LabScoreBand band) {
  switch (band) {
    case LabScoreBand.perfect:
      return const LabScoreBandStyle(
        label: 'Perfect run',
        headline: 'Every answer right on the first try.',
        color: AppColors.onSuccessContainer,
        containerColor: AppColors.successContainer,
      );
    case LabScoreBand.strong:
      return const LabScoreBandStyle(
        label: 'Strong work',
        headline: 'You moved through this one with barely a stumble.',
        color: AppColors.onPrimaryContainer,
        containerColor: AppColors.primaryContainer,
      );
    case LabScoreBand.gettingThere:
      return const LabScoreBandStyle(
        label: 'Getting there',
        headline: 'You worked for this one, and you got there.',
        color: AppColors.onTertiaryContainer,
        containerColor: AppColors.tertiaryContainer,
      );
    case LabScoreBand.needsReview:
      return const LabScoreBandStyle(
        label: 'Worth a replay',
        headline: 'You finished it. A second pass will make it stick.',
        color: AppColors.onSurfaceVariant,
        containerColor: AppColors.surfaceContainerHigh,
      );
  }
}
