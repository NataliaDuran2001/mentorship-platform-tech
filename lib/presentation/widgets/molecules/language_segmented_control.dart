// Atomic Design (Molecule): Combines atoms into a functional block.
//
// The Settings language picker (English/Español) as a two-position segmented
// control. A stacked pair of GoalRadioRow (the pattern step 3 of onboarding
// uses for its 4 goals) reads right for a list of options but is oversized
// for a plain binary choice — this is that choice's own control, not a
// second-purpose reuse of the radio-row pattern.

import 'package:flutter/material.dart';

import '../../../domain/entities/app_language.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class LanguageSegmentedControl extends StatelessWidget {
  const LanguageSegmentedControl({
    super.key,
    required this.currentLanguage,
    required this.onSelect,
    required this.isLoading,
  });

  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onSelect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            _segment(context, label: 'English', language: AppLanguage.en),
            _segment(context, label: 'Español', language: AppLanguage.es),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required AppLanguage language,
  }) {
    final isSelected = currentLanguage == language;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        label: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: isLoading ? null : () => onSelect(language),
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            child: AnimatedContainer(
              duration: AppConstants.durationFast,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingSm + 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
