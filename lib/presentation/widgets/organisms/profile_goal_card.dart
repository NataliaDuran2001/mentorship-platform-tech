// Atomic Design (Organism): Displays the user's learning goal and its progress.

import 'package:flutter/material.dart';

import '../../../domain/entities/user_profile.dart';
import '../../utils/app_colors.dart';
import '../../utils/onboarding_labels.dart';

class ProfileGoalCard extends StatelessWidget {
  const ProfileGoalCard({
    super.key,
    required this.profile,
    required this.progress,
  });

  final UserProfile profile;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final goalStr = goalName(profile.learningGoal) ?? 'Sin meta definida';
    final percentage = (progress * 100).toInt();

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metas de Aprendizaje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goalStr,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
