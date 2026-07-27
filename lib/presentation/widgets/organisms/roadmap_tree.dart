// Atomic Design (Organismo): Sección funcional reutilizable.
// El árbol de tópicos secuenciales del roadmap.
//
// **No hay mockup de esta pantalla**: el prototipo solo muestra la ruta en curso
// dentro del dashboard. El diseño se deriva del design system y de los patrones
// de card ya establecidos en el onboarding — borde de 1px, radio `lg`, el
// violeta `primary` para lo activo.
//
// Tampoco decide nada: recibe el árbol ya anidado, ordenado y con el
// `TopicStatus` puesto por GetRoadmapTreeUseCase. Solo lo pinta.

import 'package:flutter/material.dart';

import '../../../domain/entities/topic_node.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class RoadmapTree extends StatelessWidget {
  const RoadmapTree({super.key, required this.roots, this.onTopicTap});

  final List<TopicNode> roots;

  /// Se llama solo para tópicos accionables. Los bloqueados no avisan.
  final ValueChanged<TopicNode>? onTopicTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final raiz in roots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: _Modulo(nodo: raiz, onTopicTap: onTopicTap),
          ),
      ],
    );
  }
}

/// Un nodo de primer nivel con sus hijos, o un tópico suelto si no tiene.
class _Modulo extends StatelessWidget {
  const _Modulo({required this.nodo, this.onTopicTap});

  final TopicNode nodo;
  final ValueChanged<TopicNode>? onTopicTap;

  @override
  Widget build(BuildContext context) {
    if (nodo.isLeaf) return _FilaDeTopico(nodo: nodo, onTap: onTopicTap);

    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: AppConstants.borderWidth,
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Indicador(status: nodo.status),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  nodo.title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                _leyendaDe(nodo.status),
                style: textTheme.labelMedium?.copyWith(
                  color: _colorDe(nodo.status),
                ),
              ),
            ],
          ),
          if (nodo.description != null) ...[
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              nodo.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingSm),
          for (final hijo in nodo.children)
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.spacingLg,
                top: AppConstants.spacingXs,
              ),
              child: _FilaDeTopico(nodo: hijo, onTap: onTopicTap),
            ),
        ],
      ),
    );
  }
}

/// Un tópico hoja.
///
/// Los bloqueados se montan sin `onTap`, así que no responden al tap ni por
/// accidente: es lo que hace la ruta determinística en vez de un menú libre.
class _FilaDeTopico extends StatelessWidget {
  const _FilaDeTopico({required this.nodo, this.onTap});

  final TopicNode nodo;
  final ValueChanged<TopicNode>? onTap;

  @override
  Widget build(BuildContext context) {
    final bloqueado = nodo.status == TopicStatus.locked;
    final disponible = nodo.status == TopicStatus.available;
    final textTheme = Theme.of(context).textTheme;

    final contenido = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      child: Row(
        children: [
          _Indicador(status: nodo.status),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              nodo.title,
              style: textTheme.bodyMedium?.copyWith(
                color: bloqueado
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
                fontWeight: disponible ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          // La leyenda va en todas las filas y no solo en las accionables: el
          // estado tiene que ser legible sin depender del color del ícono.
          Text(
            _leyendaDe(nodo.status),
            style: textTheme.labelMedium?.copyWith(
              color: _colorDe(nodo.status),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      enabled: !bloqueado,
      button: !bloqueado,
      label: '${nodo.title}. ${_leyendaDe(nodo.status)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: disponible
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          border: disponible
              ? Border.all(
                  color: AppColors.primary,
                  width: AppConstants.borderWidth,
                )
              : null,
        ),
        child: bloqueado || onTap == null
            ? contenido
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onTap!(nodo),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusDefault),
                  child: contenido,
                ),
              ),
      ),
    );
  }
}

/// Ícono del estado. Los tres se distinguen por forma **y** por color, no solo
/// por color.
class _Indicador extends StatelessWidget {
  const _Indicador({required this.status});

  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconoDe(status),
      color: _colorDe(status),
      size: AppConstants.iconSizeSm,
    );
  }
}

IconData _iconoDe(TopicStatus status) {
  switch (status) {
    case TopicStatus.completed:
      return Icons.check_circle;
    case TopicStatus.available:
      return Icons.play_circle_outline;
    case TopicStatus.locked:
      return Icons.lock_outline;
  }
}

Color _colorDe(TopicStatus status) {
  switch (status) {
    case TopicStatus.completed:
      return AppColors.primary;
    case TopicStatus.available:
      return AppColors.primary;
    case TopicStatus.locked:
      return AppColors.onSurfaceVariant;
  }
}

String _leyendaDe(TopicStatus status) {
  switch (status) {
    case TopicStatus.completed:
      return 'Completado';
    case TopicStatus.available:
      return 'Disponible';
    case TopicStatus.locked:
      return 'Bloqueado';
  }
}

/// Estado vacío: el track no tiene tópicos cargados todavía.
///
/// Es el caso real hoy, porque el currículum es una decisión abierta del Módulo
/// 2. No puede ser una pantalla en blanco ni un error: no hay nada roto.
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
            'Tu ruta de $trackName se está armando',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Todavía no cargamos los tópicos de esta especialidad. Tu elección '
            'quedó guardada: cuando el contenido esté listo, lo vas a ver acá.',
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

/// Error de carga, con reintento.
class RoadmapErrorState extends StatelessWidget {
  const RoadmapErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Ya traducido al español.
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
            'No pudimos cargar tu ruta',
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
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
