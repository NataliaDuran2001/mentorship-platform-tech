// Atomic Design (Átomo): Componente irreductible.
// Detecta el hover del puntero y lo entrega a un builder. No pinta nada.
//
// Por qué existe: el prototipo del onboarding usa `group-hover` de Tailwind —
// pasar el mouse por la card cambia también el fondo del recuadro del ícono
// que tiene adentro. En Flutter eso necesita que alguien conozca el hover y lo
// propague hacia abajo por parámetro.
//
// Es el único widget con estado de todo el onboarding, y a propósito: el hover
// es estado efímero de presentación, no estado de la aplicación. Los signals
// de lib/presentation/state/ son para lo segundo. Meter el hover en un signal
// global lo volvería compartido entre todas las cards de la pantalla, que es
// justo lo contrario de lo que se necesita.

import 'package:flutter/material.dart';

class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder});

  /// Recibe `true` mientras el puntero está encima.
  final Widget Function(BuildContext context, bool isHovered) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(context, _isHovered),
    );
  }
}
