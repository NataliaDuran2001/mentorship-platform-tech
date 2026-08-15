import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/entities/content_translation.dart';
import '../../../domain/entities/lab_challenge.dart';
import '../../state/lab_state.dart';
import '../../state/lab_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class LabMultipleChoice extends StatelessWidget {
  const LabMultipleChoice({super.key, required this.challenge, this.translation});

  final MultipleChoiceChallenge challenge;

  /// AI-translated overlay for [challenge]'s question/description/option
  /// text, or `null` when the Settings language is English or no
  /// translation is cached yet. The option *ids* (and which one is correct)
  /// always come from [challenge] — the translation only ever supplies
  /// display text.
  final ExerciseTranslation? translation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final question = translation?.question ?? challenge.question;
    final description = translation?.description ?? challenge.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: textTheme.headlineMedium),
        if (description != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            description,
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
                final optionText = translation?.items?[entry.key] ?? entry.value;

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
                              optionText,
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
