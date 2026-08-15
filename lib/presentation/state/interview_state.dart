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

/// The role the student says they're practicing for, e.g. "Frontend
/// Developer". Optional: set on the intro page before a session starts, and
/// sent along so questions can be tailored to it.
final interviewDesiredRole = signal<String>('');

/// The role actually used for the current session, captured once at
/// `startInterviewSession()` — unlike [interviewDesiredRole] (the intro
/// page's live input), this survives the rest of the session so
/// `finishInterviewSession()` can save it alongside the result. `null` when
/// the field was left blank.
final interviewSessionRole = signal<String?>(null);

/// Index of the question currently on screen. Reaching
/// `interviewQuestions.value.length` means every question has been answered
/// locally (see [interviewAllAnswered]) and the session moves to grading.
final interviewCurrentIndex = signal<int>(0);

/// Text currently typed for the question on screen. It lives in a signal and
/// not in a TextEditingController because the widgets in this project are
/// StatelessWidget (see CustomInput).
final interviewAnswerDraft = signal<String>('');

/// Answers already typed and confirmed, keyed by question id. Collected
/// silently while the student moves through the questions — Kimi only sees
/// them once, in a single batched call, when the session is finished.
final interviewAnswers = signal<Map<String, String>>(const {});

/// Whether the one, end-of-session grading call is in flight.
final interviewSessionAnalyzing = signal<bool>(false);
final interviewSessionError = signal<String?>(null);

/// Feedback for the whole session, keyed by question id. Written once, in
/// bulk, when the batched grading call succeeds.
final interviewFeedback = signal<Map<String, InterviewAnswerFeedback>>(const {});

/// 1-2 friendly sentences on the session as a whole, from the same batched
/// call that fills [interviewFeedback].
final interviewOverallSummary = signal<String?>(null);

/// True once every question has a locally-stored answer, i.e. the student
/// reached and confirmed the last question. Distinguishes "still answering"
/// from "waiting on/showing the graded result".
final interviewAllAnswered = computed(() {
  final questions = interviewQuestions.value;
  if (questions.isEmpty) return false;
  final answers = interviewAnswers.value;
  return questions.every((q) => answers.containsKey(q.id));
});

/// Whether the batched grading call has come back and every question has
/// feedback to show.
final interviewSessionCompleted = computed(() {
  final questions = interviewQuestions.value;
  if (questions.isEmpty) return false;
  final feedback = interviewFeedback.value;
  return feedback.length == questions.length;
});

/// Resets all interview-simulator state (called on logout, and when starting
/// a new session over a finished one).
void resetInterviewState() {
  interviewQuestions.value = const [];
  interviewQuestionsLoading.value = false;
  interviewQuestionsError.value = null;
  interviewDesiredRole.value = '';
  interviewSessionRole.value = null;
  interviewCurrentIndex.value = 0;
  interviewAnswerDraft.value = '';
  interviewAnswers.value = const {};
  interviewSessionAnalyzing.value = false;
  interviewSessionError.value = null;
  interviewFeedback.value = const {};
  interviewOverallSummary.value = null;
}
