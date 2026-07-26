// Atomic Design (Organismo): Contenido placeholder de un destino del shell
// que aún no está construido. Mantiene el texto dentro del ancho legible de
// 800px que fija el design system para vistas de texto.

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PlaceholderDestino extends StatelessWidget {
  final String titulo;
  final String detalle;

  const PlaceholderDestino({
    super.key,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.maxReadableWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              detalle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
