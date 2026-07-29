import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/entities/lab_challenge.dart';
import '../../state/lab_actions.dart';
import '../../state/lab_state.dart';
import '../../state/ai_state.dart';
import '../../state/ai_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../organisms/lab_fill_blank.dart';
import '../organisms/lab_multiple_choice.dart';
import '../organisms/lab_order_logic.dart';

class LabPage extends StatefulWidget {
  const LabPage({super.key, required this.topicId});

  final String topicId;

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  @override
  void initState() {
    super.initState();
    // Start loading on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadLabs(widget.topicId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/path'),
          tooltip: 'Exit Lab',
        ),
        title: const Text('Interactive Lab'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: SignalBuilder(
            builder: (context) {
              if (labChallenges.value.isEmpty) return const SizedBox.shrink();
              final progress = (labCurrentIndex.value) / labChallenges.value.length;
              return LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              );
            },
          ),
        ),
      ),
      body: SignalBuilder(
        builder: (context) {
          if (labLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (labError.value != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: AppConstants.spacingMd),
                  Text(labError.value!, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppConstants.spacingMd),
                  ElevatedButton(
                    onPressed: () => loadLabs(widget.topicId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (labIsCompleted.value) {
            return _CompletedView();
          }

          final challenge = labCurrentChallenge.value;
          if (challenge == null) {
            return const Center(child: Text('No challenges available.'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppConstants.maxReadableWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildChallengeWidget(challenge),
                          _AiHintSection(
                            topicId: widget.topicId,
                            challenge: challenge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _BottomValidationBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChallengeWidget(LabChallenge challenge) {
    if (challenge is MultipleChoiceChallenge) {
      return LabMultipleChoice(challenge: challenge);
    } else if (challenge is FillBlankChallenge) {
      return LabFillBlank(challenge: challenge);
    } else if (challenge is OrderLogicChallenge) {
      return LabOrderLogic(challenge: challenge);
    }
    return const Text('Unknown challenge type');
  }
}

class _BottomValidationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final isValid = labIsCurrentValid.value;
        final hasSelection = labSelectedAnswers.value.isNotEmpty;

        Color barColor = AppColors.surfaceContainerLowest;
        if (isValid == true) barColor = AppColors.successContainer;
        if (isValid == false) barColor = AppColors.errorContainer;

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          decoration: BoxDecoration(
            color: barColor,
            border: const Border(
              top: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
          children: [
            Expanded(
              child: _FeedbackMessage(isValid: isValid),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            if (isValid == true)
              ElevatedButton(
                onPressed: nextLabChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onSuccess,
                ),
                child: const Text('Continue'),
              )
            else
              ElevatedButton(
                onPressed: hasSelection ? submitLabAnswer : null,
                child: const Text('Check Answer'),
              ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({required this.isValid});
  final bool? isValid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    if (isValid == null) {
      return const SizedBox.shrink();
    }
    
    if (isValid == true) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.onSuccessContainer),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              'Excellent! That is correct.',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.onSuccessContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    
    return Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.onErrorContainer),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              'Not quite right. Try again.',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
    );
  }
}

class _CompletedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SignalBuilder(
      builder: (context) {
        final saveError = labSaveError.value;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: AppConstants.iconSizeCelebration,
                color: AppColors.tertiary,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text('Lab Completed!', style: textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'You have successfully passed all the interactive challenges.',
                style: textTheme.bodyLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              // The topic is closed here, so the path is left up to date before
              // going back to it. While it is being recorded the way out is
              // held, otherwise the tree would be reached still showing the
              // topic as pending.
              if (labSavingProgress.value) ...[
                const SizedBox(height: AppConstants.spacingXl),
                const CircularProgressIndicator(),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  'Saving your progress…',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ] else if (saveError != null) ...[
                const SizedBox(height: AppConstants.spacingLg),
                Text(
                  "$saveError Your answers are safe, but the topic wasn't "
                  'marked as completed.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                const ElevatedButton(
                  onPressed: completeCurrentTopic,
                  child: Text('Retry'),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                TextButton(
                  onPressed: () => context.go('/path'),
                  child: const Text('Return to my path'),
                ),
              ] else ...[
                const SizedBox(height: AppConstants.spacingXl),
                ElevatedButton(
                  onPressed: () => context.go('/path'),
                  child: const Text('Return to my path'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AiHintSection extends StatelessWidget {
  const _AiHintSection({required this.topicId, required this.challenge});

  final String topicId;
  final LabChallenge challenge;

  String _challengeType(LabChallenge challenge) {
    if (challenge is MultipleChoiceChallenge) return 'multiple_choice';
    if (challenge is FillBlankChallenge) return 'fill_blank';
    if (challenge is OrderLogicChallenge) return 'order_logic';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final hintsList = labHints.value[topicId] ?? const <String>[];
        final textTheme = Theme.of(context).textTheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppConstants.spacingLg),
            const Divider(),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      'AI Lab Assistant',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (labHintLoading.value)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      requestLabHint(
                        topicId,
                        challenge.question,
                        _challengeType(challenge),
                      );
                    },
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(hintsList.isEmpty ? 'Get Hint' : 'Get Another Hint'),
                  ),
              ],
            ),
            if (labHintError.value != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Could not load hint. Try again.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            if (hintsList.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < hintsList.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 ',
                              style: textTheme.bodyMedium,
                            ),
                            Expanded(
                              child: Text(
                                hintsList[i],
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
