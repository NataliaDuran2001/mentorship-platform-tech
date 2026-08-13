// Presentation layer (State): Interview-practice simulator actions.
//
// Triggers the calls to the Edge Functions via InterviewRepository, handling
// the loading states and errors. Mirrors ai_actions.dart's shape.

import '../../core/di/injection.dart';
import '../../domain/repositories/interview_repository.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'interview_state.dart';

/// Starts a fresh interview-practice session, personalized to the
/// authenticated user's track, level and goal.
Future<void> startInterviewSession() async {
  final profile = currentProfile.value;
  final track = profile?.track;
  if (profile == null || track == null) return;

  resetInterviewState();
  interviewQuestionsLoading.value = true;

  try {
    final questions = await getIt<InterviewRepository>().generateQuestions(
      track: track,
      experienceLevel: profile.experienceLevel,
      learningGoal: profile.learningGoal,
    );
    interviewQuestions.value = questions;
  } catch (e) {
    interviewQuestionsError.value = errorMessage(e);
  } finally {
    interviewQuestionsLoading.value = false;
  }
}

/// Sends the currently typed answer ([interviewAnswerDraft]) for the
/// question at [interviewCurrentIndex] to Kimi3 and stores the resulting
/// feedback.
Future<void> submitInterviewAnswer() async {
  final profile = currentProfile.value;
  final track = profile?.track;
  final answerText = interviewAnswerDraft.value.trim();
  if (profile == null || track == null || answerText.isEmpty) return;

  final index = interviewCurrentIndex.value;
  final questions = interviewQuestions.value;
  if (index < 0 || index >= questions.length) return;
  final question = questions[index];

  interviewAnswerLoading.value = true;
  interviewAnswerError.value = null;

  try {
    final feedback = await getIt<InterviewRepository>().analyzeAnswer(
      question: question,
      answerText: answerText,
      track: track,
      experienceLevel: profile.experienceLevel,
    );
    interviewFeedback.value = {
      ...interviewFeedback.value,
      question.id: feedback,
    };
  } catch (e) {
    interviewAnswerError.value = errorMessage(e);
  } finally {
    interviewAnswerLoading.value = false;
  }
}

/// Moves on to the next question, if there is one, and clears the answer
/// draft so it doesn't leak into the next question's field.
void nextInterviewQuestion() {
  final next = interviewCurrentIndex.value + 1;
  interviewCurrentIndex.value = next < interviewQuestions.value.length
      ? next
      : interviewQuestions.value.length;
  interviewAnswerDraft.value = '';
}
