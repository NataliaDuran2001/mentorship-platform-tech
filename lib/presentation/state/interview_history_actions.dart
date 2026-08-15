// Presentation layer (State): Interview-practice history action.

import '../../core/di/injection.dart';
import '../../domain/repositories/interview_repository.dart';
import '../utils/auth_error_messages.dart';
import 'interview_history_state.dart';

/// Loads every saved session for the authenticated user, most recent first.
Future<void> loadInterviewHistory() async {
  interviewHistoryLoading.value = true;
  interviewHistoryError.value = null;

  try {
    interviewHistory.value = await getIt<InterviewRepository>().loadSessions();
  } catch (e) {
    interviewHistoryError.value = errorMessage(e);
  } finally {
    interviewHistoryLoading.value = false;
  }
}
