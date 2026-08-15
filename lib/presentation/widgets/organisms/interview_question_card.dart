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
import '../atoms/step_counter_label.dart';

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
  });

  final InterviewQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final String answerText;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback onSubmit;

  /// True only while the end-of-session grading call is in flight, which can
  /// only happen right after confirming the last question's answer.
  final bool isSubmitting;

  final String? errorMessage;

  bool get _isLastQuestion => questionNumber == totalQuestions;

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
            StepCounterLabel(
              currentStep: questionNumber,
              totalSteps: totalQuestions,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(question.prompt, style: textTheme.headlineSmall),
        const SizedBox(height: AppConstants.spacingLg),
        CustomInput(
          key: ValueKey(question.id),
          hintText: 'Write your answer here. There is no wrong way to start.',
          maxLines: 6,
          enabled: !isSubmitting,
          onChanged: onAnswerChanged,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            errorMessage!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppConstants.spacingMd),
        CustomButton(
          text: isSubmitting
              ? 'Checking your answers…'
              : (_isLastQuestion ? 'Finish practice' : 'Next question'),
          onPressed:
              (isSubmitting || answerText.trim().isEmpty) ? null : onSubmit,
        ),
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
