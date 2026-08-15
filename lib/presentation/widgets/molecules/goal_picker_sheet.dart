// Atomic Design (Molecule): Combines atoms into a functional block.
//
// The bottom sheet content that lets the learner re-pick their learning goal
// from the Profile page. Reuses the same GoalRadioRow + goalLabels as
// onboarding step 3 — it's the same choice, asked again later, not a second
// design for it.

import 'package:flutter/material.dart';

import '../../../domain/entities/learning_goal.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../../utils/translate.dart';
import '../organisms/auth_message.dart';
import 'goal_radio_row.dart';

class GoalPickerSheet extends StatelessWidget {
  const GoalPickerSheet({
    super.key,
    required this.currentGoal,
    required this.onSelect,
    required this.isLoading,
    this.errorMessage,
  });

  final LearningGoal? currentGoal;
  final ValueChanged<LearningGoal> onSelect;
  final bool isLoading;

  /// Already user-facing text. `null` when there is no error.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingMd,
          AppConstants.spacingLg,
          AppConstants.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
            ),
            Text(
              tr('Your learning goal', 'Tu meta de aprendizaje'),
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            if (errorMessage != null) ...[
              AuthMessage(message: errorMessage!),
              const SizedBox(height: AppConstants.spacingMd),
            ],
            for (final entry in goalLabels.entries) ...[
              GoalRadioRow(
                label: entry.value.label,
                isSelected: currentGoal == entry.key,
                onTap: isLoading ? () {} : () => onSelect(entry.key),
              ),
              const SizedBox(height: AppConstants.spacingSm),
            ],
            if (isLoading) ...[
              const SizedBox(height: AppConstants.spacingSm),
              const Center(
                child: SizedBox(
                  width: AppConstants.iconSizeSm,
                  height: AppConstants.iconSizeSm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
