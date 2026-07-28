import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/entities/lab_challenge.dart';
import '../../state/lab_state.dart';
import '../../state/lab_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class LabMultipleChoice extends StatelessWidget {
  const LabMultipleChoice({super.key, required this.challenge});

  final MultipleChoiceChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(challenge.question, style: textTheme.headlineMedium),
        if (challenge.description != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            challenge.description!,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppConstants.spacingXl),
        SignalBuilder(
          builder: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: challenge.options.entries.map((entry) {
                final isSelected = labSelectedAnswers.value['selected'] == entry.key;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                  child: InkWell(
                    onTap: () => setLabAnswer('selected', entry.key),
                    borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
                    child: Ink(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppConstants.spacingMd),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
