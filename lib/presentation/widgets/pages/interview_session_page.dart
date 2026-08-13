// Atomic Design (Page): The interview-practice session itself. Lives outside
// the shell (like LabPage/`/lab/:topicId`): it is a focused, full-screen
// flow, not a shell destination.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/interview_actions.dart';
import '../../state/interview_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../organisms/interview_feedback_card.dart';
import '../organisms/interview_question_card.dart';

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({super.key});

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startInterviewSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/interviews'),
          tooltip: 'Exit practice',
        ),
        title: const Text('Interview Practice'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: SignalBuilder(
            builder: (context) {
              final total = interviewQuestions.value.length;
              if (total == 0) return const SizedBox.shrink();
              final progress = interviewCurrentIndex.value / total;
              return LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              );
            },
          ),
        ),
      ),
      body: SignalBuilder(
        builder: (context) {
          if (interviewQuestionsLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppConstants.spacingMd),
                  Text('Getting your questions ready…'),
                ],
              ),
            );
          }

          final error = interviewQuestionsError.value;
          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: AppConstants.spacingMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingLg,
                    ),
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  const ElevatedButton(
                    onPressed: startInterviewSession,
                    child: Text('Try again'),
                  ),
                ],
              ),
            );
          }

          if (interviewSessionCompleted.value) {
            return const _CompletedView();
          }

          final questions = interviewQuestions.value;
          final index = interviewCurrentIndex.value;
          if (questions.isEmpty || index >= questions.length) {
            return const Center(child: Text('No questions available.'));
          }

          final question = questions[index];
          final feedback = interviewFeedback.value[question.id];

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
                    InterviewQuestionCard(
                      question: question,
                      questionNumber: index + 1,
                      totalQuestions: questions.length,
                      answerText: interviewAnswerDraft.value,
                      onAnswerChanged: (value) =>
                          interviewAnswerDraft.value = value,
                      onSubmit: submitInterviewAnswer,
                      isSubmitting: interviewAnswerLoading.value,
                      errorMessage: interviewAnswerError.value,
                      answerLocked: feedback != null,
                    ),
                    if (feedback != null) ...[
                      const SizedBox(height: AppConstants.spacingLg),
                      InterviewFeedbackCard(
                        feedback: feedback,
                        onContinue: nextInterviewQuestion,
                        isLastQuestion: index == questions.length - 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SignalBuilder(
      builder: (context) {
        final feedback = interviewFeedback.value.values.toList();
        final averageScore = feedback.isEmpty
            ? 0
            : (feedback.map((f) => f.score).reduce((a, b) => a + b) /
                    feedback.length)
                .round();

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: AppConstants.iconSizeCelebration,
                color: AppColors.tertiary,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text('Practice complete!', style: textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'You answered every question. Average score: $averageScore/100. '
                'Come back anytime for a new set of questions.',
                style: textTheme.bodyLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXl),
              const ElevatedButton(
                onPressed: startInterviewSession,
                child: Text('Practice again'),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => context.go('/interviews'),
                child: const Text('Back to Interviews'),
              ),
            ],
          ),
        );
      },
    );
  }
}
