// Atomic Design (Organism): Feedback for one answered interview-practice
// question. Context-free: takes the feedback entity and a callback, reads no
// signals.

import 'package:flutter/material.dart';

import '../../../domain/entities/interview_answer_feedback.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/custom_button.dart';

class InterviewFeedbackCard extends StatelessWidget {
  const InterviewFeedbackCard({
    super.key,
    required this.feedback,
    required this.onContinue,
    required this.isLastQuestion,
  });

  final InterviewAnswerFeedback feedback;
  final VoidCallback onContinue;
  final bool isLastQuestion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Coach feedback',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              _ScoreBadge(score: feedback.score),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(feedback.summary, style: textTheme.bodyMedium),
          if (feedback.strengths.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMd),
            _FeedbackList(
              icon: Icons.check_circle_outline,
              iconColor: AppColors.success,
              title: 'What went well',
              items: feedback.strengths,
            ),
          ],
          if (feedback.improvements.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMd),
            _FeedbackList(
              icon: Icons.lightbulb_outline,
              iconColor: AppColors.tertiary,
              title: 'Try this next time',
              items: feedback.improvements,
            ),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          CustomButton(
            text: isLastQuestion ? 'Finish practice' : 'Next question',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        '$score/100',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSuccessContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  const _FeedbackList({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: AppConstants.iconSizeSm, color: iconColor),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    item,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
