// Atomic Design (Organism): Reusable functional section.
// The tree of sequential roadmap topics.
//
// **There is no mockup for this screen**: the prototype only shows the path in
// progress inside the dashboard. The design is derived from the design system
// and from the card patterns already established in the onboarding — 1px
// border, `lg` radius, the `primary` purple for what is active.
//
// It does not decide anything either: it takes the tree already nested, sorted
// and with the `TopicStatus` set by GetRoadmapTreeUseCase. It only paints it.

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../domain/entities/topic_node.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/app_progress_bar.dart';

class RoadmapTree extends StatelessWidget {
  const RoadmapTree({super.key, required this.roots, this.onTopicTap});

  final List<TopicNode> roots;

  /// Called only for actionable topics. Locked ones stay silent.
  final ValueChanged<TopicNode>? onTopicTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final root in roots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: _Module(node: root, onTopicTap: onTopicTap),
          ),
      ],
    );
  }
}

/// A section of the path with its topics, or a standalone topic if it has no
/// children.
///
/// The section is the unit the learner reads the path in: it carries its own
/// name —"Basic", "Intermediate", "Advanced"— and its own progress, so the
/// path reads as a few reachable stretches instead of one long list where
/// everything past the current topic looks equally far away.
class _Module extends StatelessWidget {
  const _Module({required this.node, this.onTopicTap});

  final TopicNode node;
  final ValueChanged<TopicNode>? onTopicTap;

  @override
  Widget build(BuildContext context) {
    if (node.isLeaf) return _TopicRow(node: node, onTap: onTopicTap);

    final textTheme = Theme.of(context).textTheme;

    // Counted over leaves, the same unit the overall progress uses: a section
    // is the set of its topics, not a further thing to complete.
    final leaves = node.flattened.where((n) => n.isLeaf).toList();
    final done = leaves.where((n) => n.isCompleted).length;
    final isCurrent = node.status == TopicStatus.available;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          // The section being worked on is the only one outlined in purple, so
          // where you are is findable without reading a single row.
          color: isCurrent ? AppColors.primary : AppColors.outlineVariant,
          width: AppConstants.borderWidth,
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LevelBadge(title: node.title, status: node.status),
              const Spacer(),
              Text(
                '$done of ${leaves.length}',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (leaves.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingSm),
            AppProgressBar(
              value: done / leaves.length,
              semanticsLabel: '${node.title} progress',
            ),
          ],
          if (node.description != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              node.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingSm),
          for (final child in node.children)
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.spacingSm,
                top: AppConstants.spacingXs,
              ),
              child: _TopicRow(node: child, onTap: onTopicTap),
            ),
        ],
      ),
    );
  }
}

/// Name of the section, told apart by icon and color as well as by text.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.title, required this.status});

  final String title;
  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(status), size: AppConstants.iconSizeSm, color: color),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}

/// A leaf topic.
///
/// Locked ones are mounted without `onTap`, so they do not respond to a tap
/// even by accident: that is what makes the path deterministic instead of a
/// free menu.
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.node, this.onTap});

  final TopicNode node;
  final ValueChanged<TopicNode>? onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = node.status == TopicStatus.locked;
    final isAvailable = node.status == TopicStatus.available;
    final textTheme = Theme.of(context).textTheme;

    final content = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      child: Row(
        children: [
          _Indicator(status: node.status),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              node.title,
              style: textTheme.bodyMedium?.copyWith(
                color: isLocked
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
                fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          // The label goes on every row and not only on the actionable ones:
          // the status has to be readable without relying on the icon color.
          Text(
            _labelFor(node.status),
            style: textTheme.labelMedium?.copyWith(
              color: _colorFor(node.status),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      enabled: !isLocked,
      button: !isLocked,
      label: '${node.title}. ${_labelFor(node.status)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isAvailable
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          border: isAvailable
              ? Border.all(
                  color: AppColors.primary,
                  width: AppConstants.borderWidth,
                )
              : null,
        ),
        child: isLocked
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    if (onTap != null) {
                      onTap!(node);
                    } else {
                      context.go('/lab/${node.id}');
                    }
                  },
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusDefault),
                  child: content,
                ),
              ),
      ),
    );
  }
}

/// Status icon. The three are told apart by shape **and** by color, not by
/// color alone.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.status});

  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconFor(status),
      color: _colorFor(status),
      size: AppConstants.iconSizeSm,
    );
  }
}

IconData _iconFor(TopicStatus status) {
  switch (status) {
    case TopicStatus.completed:
      return Icons.check_circle;
    case TopicStatus.available:
      return Icons.play_circle_outline;
    case TopicStatus.locked:
      return Icons.lock_outline;
  }
}

Color _colorFor(TopicStatus status) {
  switch (status) {
    case TopicStatus.completed:
      return AppColors.primary;
    case TopicStatus.available:
      return AppColors.primary;
    case TopicStatus.locked:
      return AppColors.onSurfaceVariant;
  }
}

String _labelFor(TopicStatus status) {
  switch (status) {
    case TopicStatus.completed:
      return 'Done';
    case TopicStatus.available:
      return 'Start now';
    case TopicStatus.locked:
      return 'Locked';
  }
}

/// Empty state: the track has no topics loaded yet.
///
/// It is the real case today, because the curriculum is an open decision of
/// Module 2. It cannot be a blank screen nor an error: nothing is broken.
class RoadmapEmptyState extends StatelessWidget {
  const RoadmapEmptyState({super.key, required this.trackName});

  final String trackName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: AppConstants.borderWidth,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.route_outlined,
            size: AppConstants.iconTileSize,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Your $trackName path is being built',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            "We haven't loaded the topics for this track yet. Your choice is "
            "saved: when the content is ready, you'll see it here.",
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Load error, with retry.
class RoadmapErrorState extends StatelessWidget {
  const RoadmapErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Already user-facing text.
  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            size: AppConstants.iconTileSize,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            "We couldn't load your path",
            style: textTheme.headlineSmall
                ?.copyWith(color: AppColors.onErrorContainer),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            message,
            style: textTheme.bodyMedium
                ?.copyWith(color: AppColors.onErrorContainer),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
