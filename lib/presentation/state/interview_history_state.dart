// Presentation layer (State): Interview-practice session history.
//
// Unlike the rest of interview_state.dart, this reflects persisted data:
// it survives leaving the Interviews section, and is only refreshed by
// explicitly calling loadInterviewHistory() (interview_history_actions.dart).

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/interview_session_record.dart';

final interviewHistory = signal<List<InterviewSessionRecord>>(const []);
final interviewHistoryLoading = signal<bool>(false);
final interviewHistoryError = signal<String?>(null);

/// Average of every saved session's score, rounded — the headline stat on
/// the history screen. `null` with no sessions yet, so the UI can show an
/// empty state instead of a misleading 0.
final interviewHistoryAverageScore = computed<int?>(() {
  final sessions = interviewHistory.value;
  if (sessions.isEmpty) return null;
  final total = sessions.map((s) => s.averageScore).reduce((a, b) => a + b);
  return (total / sessions.length).round();
});
