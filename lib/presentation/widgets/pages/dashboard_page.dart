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
import '../../state/language_state.dart';
import '../../state/roadmap_state.dart';
import '../../state/roadmap_actions.dart';
import '../../state/ai_state.dart';
import '../../state/ai_actions.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/app_progress_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        // Lazy loads, fired outside the build cycle so no signal changes while
        // it is being built. The summary has its own trigger and does not ride
        // on the roadmap's: arriving here with the tree already loaded from
        // "My path" used to leave the card showing its empty-state copy.
        if (!roadmapLoaded.value && !roadmapLoading.value && roadmapError.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => loadRoadmap());
        }
        if ((dailyBrief.value == null || dailyBriefLanguage.value != appLanguage.value) &&
            !dailyBriefLoading.value &&
            dailyBriefError.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => loadDailyBrief());
        }
        // The welcome headline is this page's own AI piece, same reasoning as
        // the daily brief above — including the language-mismatch refetch.
        if ((welcomeMessage.value == null || welcomeMessageLanguage.value != appLanguage.value) &&
            !welcomeMessageLoading.value &&
            welcomeMessageError.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => loadWelcomeMessage());
        }

        final profile = currentProfile.value;
        final textTheme = Theme.of(context).textTheme;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header. AI-generated when available; falls back to the
              // static label while loading or if the request fails, same
              // degradation as the daily brief card below.
              Text(
                (welcomeMessage.value ?? tr('WELCOME BACK', 'BIENVENIDA DE NUEVO'))
                    .toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                profile?.displayName ?? tr('Learner', 'Estudiante'),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // AI Daily Brief Card
              _buildAiBriefCard(context),
              const SizedBox(height: AppConstants.spacingLg),

              // Numeric progress, then the single next action.
              _buildProgressAndActionSection(context),
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
                      tr('Your Summary', 'Tu resumen'),
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
                    dailyBrief.value ??
                        tr(
                          "We're putting your summary together. Check back in a moment!",
                          'Estamos armando tu resumen. Vuelve en un momento.',
                        ),
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
    return Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.error, size: 20),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Text(
            tr(
              "We couldn't put your summary together right now. Your progress is safe — try again.",
              'No pudimos armar tu resumen en este momento. Tu progreso está a salvo — intenta de nuevo.',
            ),
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: loadDailyBrief,
          child: Text(tr('Retry', 'Reintentar')),
        ),
      ],
    );
  }

  Widget _buildProgressAndActionSection(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total > 0) ...[
          _buildStatStrip(context, progress, completed, total),
          const SizedBox(height: AppConstants.spacingLg),
        ],
        _buildNextActionCard(context, nextTopic),
      ],
    );
  }

  /// The numeric read of the path — separate from the AI brief above (which
  /// stays a plain point of view, no figures) and no longer its own bordered
  /// card either (that was the same number said twice). Just a slim,
  /// unboxed line.
  Widget _buildStatStrip(
    BuildContext context,
    double progress,
    int completed,
    int total,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          '${(progress * 100).round()}%',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          tr('· $completed of $total topics', '· $completed de $total temas'),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(child: AppProgressBar(value: progress)),
      ],
    );
  }

  /// The one action that matters right now — the only primary-colored,
  /// full-width block on the page, so it doesn't compete in size with a
  /// purely informational card the way it used to.
  Widget _buildNextActionCard(BuildContext context, TopicNode nextTopic) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('NEXT UP', 'LO QUE SIGUE'),
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.85),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          if (nextTopic.title.isNotEmpty) ...[
            Text(
              nextTopic.title,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (nextTopic.description != null) ...[
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                nextTopic.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            Material(
              color: AppColors.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                onTap: () => context.go('/lab/${nextTopic.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingLg,
                    vertical: AppConstants.spacingSm + 2,
                  ),
                  child: Text(
                    tr('Start Lab Challenge ▸', 'Comenzar el reto ▸'),
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              tr('All caught up!', '¡Ya estás al día!'),
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              tr(
                'You have completed all available topics on your current path.',
                'Completaste todos los temas disponibles en tu ruta actual.',
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
