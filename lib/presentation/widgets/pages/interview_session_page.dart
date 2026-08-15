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
import '../atoms/app_progress_bar.dart';
import '../atoms/custom_button.dart';
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
          preferredSize: const Size.fromHeight(AppConstants.progressBarHeight),
          child: SignalBuilder(
            builder: (context) {
              final total = interviewQuestions.value.length;
              if (total == 0) return const SizedBox.shrink();
              final progress = interviewSessionCompleted.value
                  ? 1.0
                  : interviewAnswers.value.length / total;
              return AppProgressBar(
                value: progress,
                semanticsLabel:
                    'Answered ${interviewAnswers.value.length} of $total questions',
              );
            },
          ),
        ),
      ),
      body: SignalBuilder(
        builder: (context) {
          if (interviewQuestionsLoading.value) {
            return const _CenteredMessage(
              message: 'Getting your questions ready…',
              child: CircularProgressIndicator(),
            );
          }

          final error = interviewQuestionsError.value;
          if (error != null) {
            return _CenteredMessage(
              message: error,
              action: const ElevatedButton(
                onPressed: startInterviewSession,
                child: Text('Try again'),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: AppConstants.iconSizeLg,
              ),
            );
          }

          if (interviewSessionCompleted.value) {
            return const _CompletedView();
          }

          if (interviewSessionAnalyzing.value) {
            return const _CenteredMessage(
              message: 'Checking your answers…',
              child: CircularProgressIndicator(),
            );
          }

          final sessionError = interviewSessionError.value;
          if (sessionError != null) {
            return _CenteredMessage(
              message: sessionError,
              action: const ElevatedButton(
                onPressed: finishInterviewSession,
                child: Text('Try again'),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: AppConstants.iconSizeLg,
              ),
            );
          }

          final questions = interviewQuestions.value;
          final index = interviewCurrentIndex.value;
          if (questions.isEmpty || index >= questions.length) {
            return const Center(child: Text('No questions available.'));
          }

          final question = questions[index];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxReadableWidth,
                ),
                child: InterviewQuestionCard(
                  question: question,
                  questionNumber: index + 1,
                  totalQuestions: questions.length,
                  answerText: interviewAnswerDraft.value,
                  onAnswerChanged: (value) => interviewAnswerDraft.value = value,
                  onSubmit: answerCurrentQuestion,
                  isSubmitting: interviewSessionAnalyzing.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child, required this.message, this.action});

  final Widget child;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              action!,
            ],
          ],
        ),
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
        final questions = interviewQuestions.value;
        final feedback = interviewFeedback.value;
        final scores = feedback.values.map((f) => f.score).toList();
        final averageScore = scores.isEmpty
            ? 0
            : (scores.reduce((a, b) => a + b) / scores.length).round();

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
                    'Practice complete!',
                    style: textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    interviewOverallSummary.value ??
                        'You answered every question. Come back anytime for a new set of questions.',
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
                  const CustomButton(
                    text: 'Practice again',
                    onPressed: startInterviewSession,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  TextButton(
                    onPressed: () => context.go('/interviews'),
                    child: const Text('Back to Interviews'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
