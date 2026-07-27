// Atomic Design (Atom): Irreducible component.
// Detects pointer hover and hands it to a builder. It paints nothing.
//
// Why it exists: the onboarding prototype uses Tailwind's `group-hover` —
// hovering the card also changes the background of the icon box inside it. In
// Flutter that needs someone to know about the hover and pass it down by
// parameter.
//
// It's the only stateful widget in the whole onboarding, and on purpose: hover
// is ephemeral presentation state, not application state. The signals in
// lib/presentation/state/ are for the latter. Putting hover in a global signal
// would make it shared across every card on the screen, which is exactly the
// opposite of what's needed.

import 'package:flutter/material.dart';

class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder});

  /// Gets `true` while the pointer is over it.
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
