// Atomic Design (Atom): Irreducible component.
//
// A soft, single-curve colored band — the "wave" accent behind a card's
// title row. One quadratic bezier, not an illustration: kept minimal on
// purpose so it reads as texture, not decoration competing with the
// content sitting on top of it.

import 'package:flutter/material.dart';

class WaveHeader extends StatelessWidget {
  const WaveHeader({super.key, required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _WavePainter(color)),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..lineTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.3,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}
