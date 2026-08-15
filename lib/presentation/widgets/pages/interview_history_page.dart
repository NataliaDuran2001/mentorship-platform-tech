// Atomic Design (Page): List of finished interview-practice sessions. Lives
// outside the shell (like InterviewSessionPage): a focused sub-flow of
// Interviews, reached from its "Practice history" link.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/entities/app_language.dart';
import '../../../domain/entities/interview_session_record.dart';
import '../../state/interview_history_actions.dart';
import '../../state/interview_history_state.dart';
import '../../state/language_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/interview_score_bands.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/translate.dart';
import '../organisms/interview_feedback_card.dart';

class InterviewHistoryPage extends StatefulWidget {
  const InterviewHistoryPage({super.key});

  @override
  State<InterviewHistoryPage> createState() => _InterviewHistoryPageState();
}

class _InterviewHistoryPageState extends State<InterviewHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInterviewHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/interviews'),
          tooltip: tr('Back', 'Atrás'),
        ),
        title: Text(tr('Practice history', 'Historial de práctica')),
      ),
      body: SignalBuilder(
        builder: (context) {
          if (interviewHistoryLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = interviewHistoryError.value;
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: AppConstants.iconSizeLg,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: AppConstants.spacingMd),
                    ElevatedButton(
                      onPressed: loadInterviewHistory,
                      child: Text(tr('Try again', 'Intentar de nuevo')),
                    ),
                  ],
                ),
              ),
            );
          }

          final sessions = interviewHistory.value;
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history,
                      size: AppConstants.iconSizeCelebration,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      tr('No practices yet', 'Todavía no hay prácticas'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      tr(
                        'Finish an interview practice and it will show up here.',
                        'Termina una práctica de entrevista y aparecerá aquí.',
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final average = interviewHistoryAverageScore.value ?? 0;

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
                        score: average,
                        size: AppConstants.iconSizeCelebration,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      tr('Average score', 'Puntaje promedio'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      tr(
                        '${sessions.length} ${sessions.length == 1 ? 'practice' : 'practices'}',
                        '${sessions.length} ${sessions.length == 1 ? 'práctica' : 'prácticas'}',
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingXl),
                    for (final session in sessions) ...[
                      _HistoryRow(
                        session: session,
                        onTap: () =>
                            context.go('/interviews/history/${session.id}'),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session, required this.onTap});

  final InterviewSessionRecord session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final band = interviewScoreBand(session.averageScore);
    final label = session.desiredRole?.trim().isNotEmpty == true
        ? session.desiredRole!
        : (trackName(session.track) ?? session.track.slug);

    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      _formatDate(session.createdAt),
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSm,
                  vertical: AppConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: band.containerColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  '${session.averageScore}/100',
                  style: textTheme.labelMedium?.copyWith(
                    color: band.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _formatDate(DateTime date) {
  final months = appLanguage.value == AppLanguage.es ? _monthsEs : _monthsEn;
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
