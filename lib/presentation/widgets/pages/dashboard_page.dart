// Presentation layer (Page): Dashboard page showing personalized AI brief and next actions.
//
// Refactored to be AI-First:
// 1. Shows a beautiful premium "AI Daily Brief" card using Kimi3 reasoning.
// 2. Recommends the "Next Best Action" (the next unlockable topic in the roadmap).
// 3. Displays progress metrics with a modern card layout.

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/topic_node.dart';
import '../../../domain/entities/roadmap_track.dart';
import '../../state/auth_state.dart';
import '../../state/roadmap_state.dart';
import '../../state/roadmap_actions.dart';
import '../../state/ai_state.dart';
import '../../state/ai_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/onboarding_labels.dart';
import '../atoms/app_progress_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        // Trigger lazy loading of the roadmap
        if (!roadmapLoaded.value && !roadmapLoading.value && roadmapError.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            loadRoadmap();
          });
        }

        final profile = currentProfile.value;
        final trackNameStr = trackName(profile?.track) ?? 'your focus area';
        final textTheme = Theme.of(context).textTheme;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'WELCOME BACK',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                profile?.displayName ?? 'Learner',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // AI Daily Brief Card
              _buildAiBriefCard(context),
              const SizedBox(height: AppConstants.spacingLg),

              // Progress Section & Next Action side-by-side or stacked
              _buildProgressAndActionSection(context, trackNameStr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiBriefCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        gradient: const LinearGradient(
          colors: [
            AppColors.surfaceContainerLow,
            AppColors.surfaceContainerLowest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft glowing blob decoration
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      'Your Daily Update',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                if (dailyBriefLoading.value)
                  _buildLoader(context)
                else if (dailyBriefError.value != null)
                  _buildErrorState()
                else
                  Text(
                    dailyBrief.value ?? "Nothing here yet today. Keep learning and check back soon!",
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                      fontFamily: 'Geist',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 250,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.error, size: 20),
        SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Text(
            "We couldn't load your personalized update right now. Showing the basics for today instead.",
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: loadDailyBrief,
          child: Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildProgressAndActionSection(BuildContext context, String trackName) {
    final textTheme = Theme.of(context).textTheme;
    final total = roadmapLeaves.value.length;
    final completed = roadmapCompletedCount.value;
    final progress = roadmapProgress.value;

    // Find the next available topic in the roadmap
    final nextTopic = roadmapLeaves.value.firstWhere(
      (node) => node.status == TopicStatus.available,
      orElse: () => const TopicNode(
        id: '',
        trackId: RoadmapTrack.frontend,
        title: '',
        sortOrder: 0,
      ),
    );

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width <= AppConstants.breakpointTablet;

    final metricsCard = Card(
      elevation: 0,
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Track Progress',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              trackName,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            if (total > 0) ...[
              AppProgressBar(value: progress),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).round()}% Completed',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$completed of $total topics',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ] else
              Text(
                'No progress to track yet.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );

    final nextActionCard = Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Up',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            if (nextTopic.title.isNotEmpty) ...[
              Text(
                nextTopic.title,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              if (nextTopic.description != null)
                Text(
                  nextTopic.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              const SizedBox(height: AppConstants.spacingLg),
              ElevatedButton.icon(
                onPressed: () {
                  // Direct the user to the lab for the next topic
                  context.go('/lab/${nextTopic.id}');
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Start Lab Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'All caught up!',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'You have completed all available topics on your current path.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          metricsCard,
          const SizedBox(height: AppConstants.spacingMd),
          nextActionCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: metricsCard),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(child: nextActionCard),
      ],
    );
  }
}
