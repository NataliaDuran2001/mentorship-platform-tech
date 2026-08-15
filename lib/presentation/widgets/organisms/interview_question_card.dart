// Atomic Design (Organism): One interview-practice question with its answer
// field. Context-free like LoginForm: it takes the current answer text and
// every callback, and reads no signals itself — InterviewSessionPage owns
// the state.

import 'package:flutter/material.dart';

import '../../../domain/entities/interview_question.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_input.dart';
import '../atoms/interview_category_tag.dart';

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
        // Which question this is stays on the AppBar's step dots only — a
        // second "STEP n OF m" text here just repeated the same fact in a
        // different style.
        InterviewCategoryTag(category: question.category),
        const SizedBox(height: AppConstants.spacingMd),
        Text(question.prompt, style: textTheme.headlineSmall),
        const SizedBox(height: AppConstants.spacingLg),
        CustomInput(
          key: ValueKey(question.id),
          hintText: tr(
            'Write your answer here. There is no wrong way to start.',
            'Escribe tu respuesta aquí. No hay una forma incorrecta de empezar.',
          ),
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
              ? tr('Checking your answers…', 'Revisando tus respuestas…')
              : (_isLastQuestion
                  ? tr('Finish practice', 'Terminar práctica')
                  : tr('Next question', 'Siguiente pregunta')),
          onPressed:
              (isSubmitting || answerText.trim().isEmpty) ? null : onSubmit,
        ),
      ],
    );
  }
}
