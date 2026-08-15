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

import '../../../domain/entities/content_translation.dart';
import '../../../domain/entities/topic_node.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/app_progress_bar.dart';
import '../atoms/wave_header.dart';

/// Title of [node] in the learner's Settings language: the AI-translated
/// overlay if there is one cached for it, English otherwise. English is
/// never missing — it is the seeded source of truth — so this never falls
/// back to a placeholder.
String _titleFor(TopicNode node, Map<String, TopicTranslation> translations) {
  return translations[node.id]?.title ?? node.title;
}

/// Description of [node] the same way as [_titleFor].
String? _descriptionFor(TopicNode node, Map<String, TopicTranslation> translations) {
  final translated = translations[node.id];
  if (translated == null) return node.description;
  // A translation always carries its own description slot (possibly null),
  // so an explicitly-null translated description must not fall back to the
  // English one — that would silently mix languages on the same card.
  return translated.description;
}

/// One color per level, cycling if there are ever more than 3 roots. Purple
/// for the first level (unchanged from before this round), then the
/// secondary violet, then the tertiary mustard — the only currently-unused
/// accent in the palette — so each section reads as its own place on the
/// path rather than a repeat of the same purple card.
const _levelColors = [AppColors.primary, AppColors.secondary, AppColors.tertiary];

Color _levelColor(int index) => _levelColors[index % _levelColors.length];

class RoadmapTree extends StatelessWidget {
  const RoadmapTree({
    super.key,
    required this.roots,
    this.onTopicTap,
    this.translations = const {},
  });

  final List<TopicNode> roots;

  /// Called only for actionable topics. Locked ones stay silent.
  final ValueChanged<TopicNode>? onTopicTap;

  /// AI-translated title/description overlay, keyed by topic id. Empty when
  /// the Settings language is English, since English is the seeded content
  /// itself and needs no overlay.
  final Map<String, TopicTranslation> translations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, root) in roots.indexed) ...[
          if (index > 0)
            _LevelConnector(
              color: _levelColor(index - 1),
              completed: roots[index - 1].status == TopicStatus.completed,
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: _Module(
              node: root,
              levelColor: _levelColor(index),
              onTopicTap: onTopicTap,
              translations: translations,
            ),
          ),
        ],
      ],
    );
  }
}

/// The thread tying two level sections into one path: a short line with a
/// dot, solid in the color of the section just finished, muted otherwise.
class _LevelConnector extends StatelessWidget {
  const _LevelConnector({required this.color, required this.completed});

  final Color color;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = completed ? color : AppColors.outlineVariant;

    return Center(
      child: Column(
        children: [
          Container(
            width: AppConstants.borderWidthThick,
            height: AppConstants.levelConnectorHeight / 2,
            color: resolvedColor,
          ),
          Container(
            width: AppConstants.levelConnectorDotSize,
            height: AppConstants.levelConnectorDotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: resolvedColor,
            ),
          ),
          Container(
            width: AppConstants.borderWidthThick,
            height: AppConstants.levelConnectorHeight / 2,
            color: resolvedColor,
          ),
        ],
      ),
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
  const _Module({
    required this.node,
    required this.levelColor,
    this.onTopicTap,
    this.translations = const {},
  });

  final TopicNode node;
  final Color levelColor;
  final ValueChanged<TopicNode>? onTopicTap;
  final Map<String, TopicTranslation> translations;

  @override
  Widget build(BuildContext context) {
    if (node.isLeaf) {
      return _TopicRow(node: node, onTap: onTopicTap, translations: translations);
    }

    final textTheme = Theme.of(context).textTheme;
    final title = _titleFor(node, translations);
    final description = _descriptionFor(node, translations);

    // Counted over leaves, the same unit the overall progress uses: a section
    // is the set of its topics, not a further thing to complete.
    final leaves = node.flattened.where((n) => n.isLeaf).toList();
    final done = leaves.where((n) => n.isCompleted).length;
    final isCurrent = node.status == TopicStatus.available;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            // The section being worked on is the only one outlined, so where
            // you are is findable without reading a single row — now in the
            // section's own color instead of always purple.
            color: isCurrent ? levelColor : AppColors.outlineVariant,
            width: AppConstants.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WaveHeader(
              color: levelColor.withValues(alpha: 0.15),
              height: AppConstants.waveHeaderHeight,
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _LevelBadge(
                        title: title,
                        status: node.status,
                        color: levelColor,
                      ),
                      const Spacer(),
                      Text(
                        tr(
                          '$done of ${leaves.length}',
                          '$done de ${leaves.length}',
                        ),
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
                      semanticsLabel: tr('$title progress', 'Progreso de $title'),
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      description,
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
                      child: _TopicRow(
                        node: child,
                        onTap: onTopicTap,
                        translations: translations,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name of the section, told apart by icon and color as well as by text.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.title,
    required this.status,
    required this.color,
  });

  final String title;
  final TopicStatus status;

  /// The section's level color, when it isn't locked. Locked stays gray
  /// regardless of level — that distinction matters more than the color
  /// identity.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        status == TopicStatus.locked ? AppColors.onSurfaceVariant : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(status),
            size: AppConstants.iconSizeSm,
            color: resolvedColor,
          ),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: resolvedColor,
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
  const _TopicRow({required this.node, this.onTap, this.translations = const {}});

  final TopicNode node;
  final ValueChanged<TopicNode>? onTap;
  final Map<String, TopicTranslation> translations;

  @override
  Widget build(BuildContext context) {
    final isLocked = node.status == TopicStatus.locked;
    final isAvailable = node.status == TopicStatus.available;
    final textTheme = Theme.of(context).textTheme;
    final title = _titleFor(node, translations);

    final content = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      child: Row(
        children: [
          _Indicator(status: node.status),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              title,
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
      label: '$title. ${_labelFor(node.status)}',
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
      return tr('Done', 'Hecho');
    case TopicStatus.available:
      return tr('Start now', 'Comenzar ahora');
    case TopicStatus.locked:
      return tr('Locked', 'Bloqueado');
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
            tr(
              'Your $trackName path is being built',
              'Tu camino de $trackName se está construyendo',
            ),
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            tr(
              "We haven't loaded the topics for this track yet. Your choice is "
              "saved: when the content is ready, you'll see it here.",
              'Todavía no hemos cargado los temas de este camino. Tu elección '
              'está guardada: cuando el contenido esté listo, lo verás aquí.',
            ),
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
            tr("We couldn't load your path", 'No pudimos cargar tu camino'),
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
            label: Text(tr('Try again', 'Intentar de nuevo')),
          ),
        ],
      ),
    );
  }
}
