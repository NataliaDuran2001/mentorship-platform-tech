import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/entities/lab_challenge.dart';
import '../../state/lab_actions.dart';
import '../../state/lab_state.dart';
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
                      child: _buildChallengeWidget(challenge),
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: AppColors.tertiary),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Lab Completed!', style: textTheme.headlineLarge),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'You have successfully passed all the interactive challenges.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppConstants.spacingXl),
          ElevatedButton(
            onPressed: () => context.go('/path'),
            child: const Text('Return to my path'),
          ),
        ],
      ),
    );
  }
}
