// Atomic Design (Organism): One question's graded feedback on the
// interview-practice results screen. Context-free: takes the question text,
// category and feedback entity, reads no signals.
//
// Collapsed by default: with 5 questions on screen at once, showing every
// summary and every bullet list up front reads as a wall of text. The
// header (category, band, question, score) is always visible so the results
// are still scannable at a glance; the written feedback only shows once
// tapped.

import 'package:flutter/material.dart';

import '../../../domain/entities/interview_answer_feedback.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/interview_score_bands.dart';
import '../../utils/translate.dart';
import '../atoms/interview_category_tag.dart';

class InterviewFeedbackCard extends StatefulWidget {
  const InterviewFeedbackCard({
    super.key,
    required this.index,
    required this.questionPrompt,
    required this.category,
    required this.feedback,
  });

  /// 1-based position of this question in the session, painted as a small
  /// leading "Q{n}" chip so the list reads as a numbered breakdown.
  final int index;
  final String questionPrompt;
  final String category;
  final InterviewAnswerFeedback feedback;

  @override
  State<InterviewFeedbackCard> createState() => _InterviewFeedbackCardState();
}

class _InterviewFeedbackCardState extends State<InterviewFeedbackCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final band = interviewScoreBand(widget.feedback.score);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: AppConstants.iconSizeSm,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        'Q${widget.index}',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppConstants.spacingXs,
                            runSpacing: AppConstants.spacingXs,
                            children: [
                              InterviewCategoryTag(category: widget.category),
                              ScoreBandBadge(band: band),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          Text(
                            widget.questionPrompt,
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Column(
                      children: [
                        ScoreGauge(
                          score: widget.feedback.score,
                          size: AppConstants.iconSizeLg,
                        ),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.onSurfaceVariant,
                          semanticLabel: _expanded
                              ? tr('Show less', 'Mostrar menos')
                              : tr('Show feedback', 'Mostrar feedback'),
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: AppConstants.durationMedium,
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: !_expanded
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppConstants.spacingSm),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                AppConstants.spacingSm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusDefault,
                                ),
                              ),
                              child: Text(
                                widget.feedback.summary,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            if (widget.feedback.strengths.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingMd),
                              _FeedbackList(
                                icon: Icons.check_circle_outline,
                                iconColor: AppColors.success,
                                title: tr(
                                  'What went well',
                                  'Lo que hiciste bien',
                                ),
                                items: widget.feedback.strengths,
                              ),
                            ],
                            if (widget.feedback.improvements.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingMd),
                              _FeedbackList(
                                icon: Icons.lightbulb_outline,
                                iconColor: AppColors.tertiary,
                                title: tr(
                                  'Try this next time',
                                  'Para la próxima',
                                ),
                                items: widget.feedback.improvements,
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular score-out-of-100 gauge with the number in the middle, colored
/// by [interviewScoreBand]. Shared by the per-question cards and the
/// session-overall summary, so a 22/100 reads as a shape and a color, not
/// just a bare number.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, required this.size, this.color});

  final int score;
  final double size;

  /// Overrides the band color for both the ring and the number. Needed on a
  /// solid `primary` background (the results hero panel, the history
  /// average card): the "Good" band's color is a dark purple meant to sit
  /// on its own pale container, and would all but disappear on `primary`
  /// itself. Leave null anywhere the gauge sits on a light/neutral surface,
  /// where the band color is what makes a 72/100 read as good at a glance.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? interviewScoreBand(score).color;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: AppConstants.gaugeStrokeWidth,
            backgroundColor: color == null
                ? AppColors.surfaceContainerHigh
                : color!.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: resolvedColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// The friendly-label pill for a score's band (e.g. "Good"). Shared by the
/// feedback card and the history list, so a score reads the same way
/// wherever it shows up instead of getting a bespoke pill per screen.
///
/// [score] is optional: the feedback card already shows the number in its
/// [ScoreGauge] right next to this badge, so repeating it here would just
/// be noise — it only passes the band. The history list has no gauge next
/// to its row, so it passes [score] too, and the badge is the only place
/// the number shows there.
class ScoreBandBadge extends StatelessWidget {
  const ScoreBandBadge({super.key, required this.band, this.score});

  final InterviewScoreBand band;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final text = score == null ? band.label : '$score · ${band.label}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: band.containerColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: band.color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  const _FeedbackList({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppConstants.iconSizeSm, color: iconColor),
              const SizedBox(width: AppConstants.spacingXs),
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(
                top: AppConstants.spacingXs,
                left: AppConstants.iconSizeSm + AppConstants.spacingXs,
              ),
              child: Text(
                item,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
