import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/entities/lab_challenge.dart';
import '../../../core/theme/app_theme.dart';
import '../../state/lab_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class LabOrderLogic extends StatelessWidget {
  const LabOrderLogic({super.key, required this.challenge});

  final OrderLogicChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Initialize state if empty
    if (labSelectedAnswers.value.isEmpty) {
      final initialOrder = challenge.blocks.keys.toList();
      // Simple shuffle to avoid showing the correct order initially
      // (in a real app, do a proper shuffle, here we just reverse for predictability)
      initialOrder.reversed.toList();
      
      final Map<String, String> initialAnswers = {};
      for (int i = 0; i < initialOrder.length; i++) {
        initialAnswers[i.toString()] = initialOrder[i];
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (labSelectedAnswers.value.isEmpty) {
          labSelectedAnswers.value = initialAnswers;
        }
      });
    }

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
            final currentOrderKeys = List.generate(
              challenge.blocks.length,
              (index) => labSelectedAnswers.value[index.toString()],
            );

            if (currentOrderKeys.any((k) => k == null)) {
              return const SizedBox.shrink();
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) {
                  final keysList = List<String>.from(currentOrderKeys.whereType<String>());
                  final item = keysList.removeAt(oldIndex);
                  keysList.insert(newIndex, item);

                  final Map<String, String> newAnswers = {};
                  for (int i = 0; i < keysList.length; i++) {
                    newAnswers[i.toString()] = keysList[i];
                  }
                  labSelectedAnswers.value = newAnswers;
                  labIsCurrentValid.value = null; // Reset validation on move
                },
                children: currentOrderKeys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final blockKey = entry.value!;
                  final blockText = challenge.blocks[blockKey]!;
                  
                  return ReorderableDragStartListener(
                    key: ValueKey(blockKey),
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMd,
                        vertical: AppConstants.spacingXs,
                      ),
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
                        border: Border.all(color: AppColors.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: AppConstants.spacingMd),
                          Expanded(
                            child: Text(blockText, style: AppTheme.code),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
