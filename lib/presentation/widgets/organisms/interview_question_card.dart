// Atomic Design (Organism): One interview-practice question with its answer
// field. Context-free like LoginForm: it takes the current answer text and
// every callback, and reads no signals itself — InterviewSessionPage owns
// the state.

import 'package:flutter/material.dart';

import '../../../domain/entities/interview_question.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';

class InterviewQuestionCard extends StatelessWidget {
  const InterviewQuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.answerText,
    required this.onAnswerChanged,
    required this.onSubmit,
    required this.isSubmitting,
    this.errorMessage,
    this.answerLocked = false,
  });

  final InterviewQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final String answerText;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String? errorMessage;

  /// True once feedback for this question already came back: the answer is
  /// no longer editable, so the student reads their own answer next to it.
  final bool answerLocked;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _CategoryTag(category: question.category),
            const Spacer(),
            Text(
              'Question $questionNumber of $totalQuestions',
              style: textTheme.bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(question.prompt, style: textTheme.headlineSmall),
        const SizedBox(height: AppConstants.spacingLg),
        CustomInput(
          hintText: 'Type your answer here. There is no wrong way to start.',
          maxLines: 6,
          enabled: !answerLocked && !isSubmitting,
          onChanged: onAnswerChanged,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            errorMessage!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        if (!answerLocked) ...[
          const SizedBox(height: AppConstants.spacingMd),
          CustomButton(
            text: isSubmitting ? 'Reading your answer…' : 'Get feedback',
            onPressed: (isSubmitting || answerText.trim().isEmpty)
                ? null
                : onSubmit,
          ),
        ],
      ],
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final label = category == 'behavioral' ? 'About you' : 'About the job';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onPrimaryFixed,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
