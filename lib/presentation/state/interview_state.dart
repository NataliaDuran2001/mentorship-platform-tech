// Presentation layer (State): State for the interview-practice simulator.
//
// Declarations of signals only. The actions are in interview_actions.dart.
//
// A session is ephemeral, like the Lab: nothing here is persisted, it only
// lives for as long as the user stays on the session screen.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/interview_answer_feedback.dart';
import '../../domain/entities/interview_question.dart';

/// Questions generated for the current session, in order.
final interviewQuestions = signal<List<InterviewQuestion>>(const []);
final interviewQuestionsLoading = signal<bool>(false);
final interviewQuestionsError = signal<String?>(null);

/// Index of the question currently on screen. Reaching
/// `interviewQuestions.value.length` means the session is complete.
final interviewCurrentIndex = signal<int>(0);

/// Feedback already received, keyed by question id.
final interviewFeedback = signal<Map<String, InterviewAnswerFeedback>>(const {});
final interviewAnswerLoading = signal<bool>(false);
final interviewAnswerError = signal<String?>(null);

/// Text currently typed for the question on screen. It lives in a signal and
/// not in a TextEditingController because the widgets in this project are
/// StatelessWidget (see CustomInput).
final interviewAnswerDraft = signal<String>('');

/// Whether every question in the session already has feedback.
final interviewSessionCompleted = computed(() {
  final questions = interviewQuestions.value;
  if (questions.isEmpty) return false;
  final feedback = interviewFeedback.value;
  return questions.every((q) => feedback.containsKey(q.id));
});

/// Resets all interview-simulator state (called on logout, and when starting
/// a new session over a finished one).
void resetInterviewState() {
  interviewQuestions.value = const [];
  interviewQuestionsLoading.value = false;
  interviewQuestionsError.value = null;
  interviewCurrentIndex.value = 0;
  interviewFeedback.value = const {};
  interviewAnswerLoading.value = false;
  interviewAnswerError.value = null;
  interviewAnswerDraft.value = '';
}
