// Atomic Design (Page): Read-only detail of one saved interview-practice
// session, reached by tapping a row on InterviewHistoryPage. Reuses
// InterviewResultsView — the same layout the live completion screen shows,
// fed from a stored InterviewSessionRecord instead of live session state.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/entities/interview_session_record.dart';
import '../../state/interview_history_actions.dart';
import '../../state/interview_history_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/translate.dart';
import '../organisms/interview_results_view.dart';

class InterviewHistoryDetailPage extends StatefulWidget {
  const InterviewHistoryDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<InterviewHistoryDetailPage> createState() =>
      _InterviewHistoryDetailPageState();
}

class _InterviewHistoryDetailPageState
    extends State<InterviewHistoryDetailPage> {
  @override
  void initState() {
    super.initState();
    // Covers a direct load of this URL (refresh/deep link), where the list
    // page never ran and interviewHistory is still empty.
    if (interviewHistory.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadInterviewHistory();
      });
    }
  }

  InterviewSessionRecord? _findSession() {
    for (final session in interviewHistory.value) {
      if (session.id == widget.sessionId) return session;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/interviews/history'),
          tooltip: tr('Back', 'Atrás'),
        ),
        title: Text(tr('Practice details', 'Detalle de práctica')),
      ),
      body: SignalBuilder(
        builder: (context) {
          final session = _findSession();
          if (session == null) {
            if (interviewHistoryLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Text(
                tr('Session not found.', 'No se encontró la sesión.'),
              ),
            );
          }

          final label = session.desiredRole?.trim().isNotEmpty == true
              ? session.desiredRole!
              : (trackName(session.track) ?? session.track.slug);

          return InterviewResultsView(
            title: label,
            summary: session.overallSummary ??
                tr(
                  'You answered every question in this practice.',
                  'Respondiste todas las preguntas de esta práctica.',
                ),
            averageScore: session.averageScore,
            questions: session.questions,
            feedback: {
              for (final feedback in session.feedback)
                feedback.questionId: feedback,
            },
            actions: TextButton(
              onPressed: () => context.go('/interviews/history'),
              child: Text(tr('Back to history', 'Volver al historial')),
            ),
          );
        },
      ),
    );
  }
}
