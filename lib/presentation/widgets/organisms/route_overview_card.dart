// Atomic Design (Organism): Displays the user's roadmap progress and
// learning goal together.
//
// Merges what used to be two separate cards (RoadmapProgressCard and
// ProfileGoalCard): both showed the same roadmap-completion percentage, the
// second one dressed up as if the *goal* itself had progress, which it
// doesn't — picking "land my first job" isn't 42% done because 42% of the
// roadmap is. The ring stays the one real number; the goal is a plain,
// editable fact below it.

import 'package:flutter/material.dart';

import '../../../domain/entities/learning_goal.dart';
import '../../../domain/entities/roadmap_track.dart';
import '../../utils/app_colors.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/translate.dart';

class RouteOverviewCard extends StatelessWidget {
  const RouteOverviewCard({
    super.key,
    required this.track,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.goal,
    required this.onEditGoal,
  });

  final RoadmapTrack? track;
  final double progress;
  final int completedCount;
  final int totalCount;
  final LearningGoal? goal;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percentage = (progress * 100).toInt();
    final trackStr = trackName(track) ?? tr('No focus yet', 'Sin enfoque aún');
    final goalStr = goalName(goal) ?? tr('No goal yet', 'Sin meta aún');

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceContainerHighest),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Your path', 'Tu ruta'),
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Centered explicitly: the outer Column stretches its children
            // (the goal box below needs full width), and without this Center
            // that stretch also forces this SizedBox's width to the card's
            // full width while its height stays 140 — an oval, not a ring.
            // Center loosens the incoming constraints before they reach it.
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percentage%',
                            style: textTheme.headlineLarge?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('COMPLETE', 'COMPLETO'),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              trackStr,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              tr(
                '$completedCount of $totalCount topics',
                '$completedCount de $totalCount temas',
              ),
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onEditGoal,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('GOAL', 'META'),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goalStr,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr('Edit', 'Editar'),
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
