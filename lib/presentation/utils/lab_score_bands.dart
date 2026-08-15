// Presentation layer (Util): Renders a LabScoreBand as a label, a headline and
// a color pair, so the screen that closes a lab never shows a bare "4 / 5".
// Mirrors interview_score_bands.dart, and like it uses only existing AppColors
// tokens — no new colors for this feature.
//
// The weakest band is deliberately NOT red, and its copy leads with what was
// achieved rather than what was missed. Reaching this screen at all means the
// section was finished and every challenge was eventually answered right —
// somebody who retried a lot did not fail, they persisted. Error red and a
// deficit-first sentence would tell them the opposite of what happened, and
// the learner most at risk of quitting is exactly the one who lands here.

import 'package:flutter/material.dart';

import '../../domain/entities/lab_score.dart';
import 'app_colors.dart';
import 'translate.dart';

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

/// Reads the language signal through [tr], so it must be called from inside a
/// reactive scope — which it is: the card that uses it renders under the
/// closing screen's `SignalBuilder`.
LabScoreBandStyle labScoreBandStyle(LabScoreBand band) {
  switch (band) {
    case LabScoreBand.perfect:
      return LabScoreBandStyle(
        label: tr('Perfect run', 'Ronda perfecta'),
        headline: tr(
          'Every single one on the first try. You own this topic.',
          'Todas al primer intento. Dominas este tema.',
        ),
        color: AppColors.onSuccessContainer,
        containerColor: AppColors.successContainer,
      );
    case LabScoreBand.strong:
      return LabScoreBandStyle(
        label: tr('Strong work', 'Muy bien'),
        headline: tr(
          'Almost a clean sweep. This one is yours.',
          'Casi impecable. Este tema ya es tuyo.',
        ),
        color: AppColors.onPrimaryContainer,
        containerColor: AppColors.primaryContainer,
      );
    case LabScoreBand.gettingThere:
      return LabScoreBandStyle(
        label: tr('Getting there', 'Vas por buen camino'),
        headline: tr(
          'You worked it out yourself. That is the kind that sticks.',
          'Lo resolviste por tu cuenta. Así es como se aprende de verdad.',
        ),
        color: AppColors.onTertiaryContainer,
        containerColor: AppColors.tertiaryContainer,
      );
    case LabScoreBand.needsReview:
      return LabScoreBandStyle(
        label: tr('You made it through', 'Lo lograste'),
        headline: tr(
          'This one fought back and you finished it anyway. '
              'Run it again and watch how much easier it feels.',
          'Este se resistió y aun así lo terminaste. '
              'Repítelo y vas a ver lo fácil que se siente.',
        ),
        color: AppColors.onSurfaceVariant,
        containerColor: AppColors.surfaceContainerHigh,
      );
  }
}
