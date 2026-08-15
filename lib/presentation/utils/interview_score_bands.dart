// Presentation layer (Util): Maps an interview-feedback score to a
// friendly label and color pair, so the results screen never shows a bare
// number without a plain-language read on it. Uses only existing
// AppColors tokens — no new colors for this feature.

import 'package:flutter/material.dart';

import 'app_colors.dart';

class InterviewScoreBand {
  const InterviewScoreBand({
    required this.label,
    required this.color,
    required this.containerColor,
  });

  /// Plain-language read on the score, e.g. "Excellent".
  final String label;

  /// Foreground color for text/icons on top of [containerColor].
  final Color color;

  /// Background color for the badge/gauge.
  final Color containerColor;
}

/// Picks the band a 0-100 [score] falls into.
InterviewScoreBand interviewScoreBand(int score) {
  if (score >= 85) {
    return const InterviewScoreBand(
      label: 'Excellent',
      color: AppColors.onSuccessContainer,
      containerColor: AppColors.successContainer,
    );
  }
  if (score >= 65) {
    return const InterviewScoreBand(
      label: 'Good',
      color: AppColors.onPrimaryContainer,
      containerColor: AppColors.primaryContainer,
    );
  }
  if (score >= 40) {
    return const InterviewScoreBand(
      label: 'Getting there',
      color: AppColors.onTertiaryContainer,
      containerColor: AppColors.tertiaryContainer,
    );
  }
  return const InterviewScoreBand(
    label: 'Keep practicing',
    color: AppColors.onErrorContainer,
    containerColor: AppColors.errorContainer,
  );
}
