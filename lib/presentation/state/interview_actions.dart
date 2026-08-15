// Presentation layer (State): Interview-practice simulator actions.
//
// Triggers the calls to the Edge Functions via InterviewRepository, handling
// the loading states and errors. Mirrors ai_actions.dart's shape.

import '../../core/di/injection.dart';
import '../../domain/repositories/interview_repository.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'interview_state.dart';
import 'language_state.dart';

/// Starts a fresh interview-practice session, personalized to the
/// authenticated user's track, level and goal, and to [interviewDesiredRole]
/// when the student filled it in.
Future<void> startInterviewSession() async {
  final profile = currentProfile.value;
  final track = profile?.track;
  if (profile == null || track == null) return;

  final desiredRole = interviewDesiredRole.value.trim();
  resetInterviewState();
  interviewSessionRole.value = desiredRole.isEmpty ? null : desiredRole;
  interviewQuestionsLoading.value = true;

  try {
    final questions = await getIt<InterviewRepository>().generateQuestions(
      track: track,
      experienceLevel: profile.experienceLevel,
      learningGoal: profile.learningGoal,
      desiredRole: interviewSessionRole.value,
      language: appLanguage.value,
    );
    interviewQuestions.value = questions;
  } catch (e) {
    interviewQuestionsError.value = errorMessage(e);
  } finally {
    interviewQuestionsLoading.value = false;
  }
}

/// Confirms the currently typed answer for the question at
/// [interviewCurrentIndex], stores it locally, and moves on — no AI call
/// happens here. On the last question it triggers [finishInterviewSession]
/// instead of just advancing.
void answerCurrentQuestion() {
  final answerText = interviewAnswerDraft.value.trim();
  if (answerText.isEmpty) return;

  final index = interviewCurrentIndex.value;
  final questions = interviewQuestions.value;
  if (index < 0 || index >= questions.length) return;
  final question = questions[index];

  interviewAnswers.value = {
    ...interviewAnswers.value,
    question.id: answerText,
  };
  interviewAnswerDraft.value = '';

  if (index == questions.length - 1) {
    finishInterviewSession();
  } else {
    interviewCurrentIndex.value = index + 1;
  }
}

/// Sends every collected answer to Kimi3 in a single call and stores the
/// resulting session feedback. Answers stay in [interviewAnswers] on
/// failure so a retry doesn't lose what the student already wrote.
Future<void> finishInterviewSession() async {
  final profile = currentProfile.value;
  final track = profile?.track;
  if (profile == null || track == null) return;

  interviewSessionAnalyzing.value = true;
  interviewSessionError.value = null;

  try {
    final result = await getIt<InterviewRepository>().analyzeSession(
      questions: interviewQuestions.value,
      answers: interviewAnswers.value,
      track: track,
      experienceLevel: profile.experienceLevel,
      language: appLanguage.value,
    );
    interviewFeedback.value = {
      for (final feedback in result.results) feedback.questionId: feedback,
    };
    interviewOverallSummary.value = result.overallSummary;

    // Best-effort: a save failure must never hide the results the student
    // already earned, so it is swallowed rather than surfaced as an error.
    try {
      await getIt<InterviewRepository>().saveSession(
        track: track,
        desiredRole: interviewSessionRole.value,
        questions: interviewQuestions.value,
        answers: interviewAnswers.value,
        feedback: result,
      );
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('Could not save interview session to history: $e');
        return true;
      }());
    }
  } catch (e) {
    interviewSessionError.value = errorMessage(e);
  } finally {
    interviewSessionAnalyzing.value = false;
  }
}
