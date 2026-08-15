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
              Center(
                child: ScoreGauge(
                  score: averageScore,
                  size: AppConstants.iconSizeCelebration,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
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
              const SizedBox(height: AppConstants.spacingXl),
              for (final question in questions)
                if (feedback[question.id] case final questionFeedback?) ...[
                  InterviewFeedbackCard(
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
