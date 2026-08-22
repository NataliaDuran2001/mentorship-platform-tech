// Atomic Design (Organism): The full results screen of an interview-practice
// session — overall score gauge, headline, summary and every question's
// feedback card. Context-free: takes plain data and an `actions` slot for
// the trailing buttons, reads no signals itself.
//
// Shared by the live completion screen (interview_session_page.dart, fed
// from the signals of the session that just finished) and the history
// detail page (interview_history_detail_page.dart, fed from a saved
// InterviewSessionRecord) — same view, two different data sources.

import 'package:flutter/material.dart';

import '../../../domain/entities/interview_answer_feedback.dart';
import '../../../domain/entities/interview_question.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/interview_score_bands.dart';
import '../../utils/translate.dart';
import '../atoms/wave_header.dart';
import 'interview_feedback_card.dart';

class InterviewResultsView extends StatelessWidget {
  const InterviewResultsView({
    super.key,
    required this.title,
    required this.summary,
    required this.averageScore,
    required this.questions,
    required this.feedback,
    required this.actions,
  });

  final String title;
  final String summary;
  final int averageScore;
  final List<InterviewQuestion> questions;
  final Map<String, InterviewAnswerFeedback> feedback;

  /// The trailing buttons — different per caller (e.g. "Practice again" /
  /// "Back to Interviews" live, just "Back" from history).
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final band = interviewScoreBand(averageScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxReadableWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                summary,
                style: textTheme.bodyLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              // Same light-card + WaveHeader language as a roadmap module
              // card: the gauge's own band color is the accent, so this
              // reads as one family with the rest of the app instead of a
              // second, louder "hero" competing with the CTA below.
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(color: band.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      WaveHeader(
                        color: band.color.withValues(alpha: 0.15),
                        height: AppConstants.waveHeaderHeight,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingLg,
                        ),
                        child: Column(
                          children: [
                            Text(
                              tr('OVERALL SCORE', 'PUNTAJE GENERAL'),
                              style: textTheme.labelMedium?.copyWith(
                                color: band.color,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            ScoreGauge(
                              score: averageScore,
                              size: AppConstants.iconSizeCelebration,
                            ),
                            const SizedBox(height: AppConstants.spacingXs),
                            Text(
                              band.label,
                              style: textTheme.labelLarge?.copyWith(
                                color: band.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              if (questions.isNotEmpty) ...[
                Text(
                  tr('Detailed breakdown', 'Desglose detallado'),
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.spacingMd),
              ],
              for (final (index, question) in questions.indexed)
                if (feedback[question.id] case final questionFeedback?) ...[
                  InterviewFeedbackCard(
                    index: index + 1,
                    questionPrompt: question.prompt,
                    category: question.category,
                    feedback: questionFeedback,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                ],
              const SizedBox(height: AppConstants.spacingMd),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}
