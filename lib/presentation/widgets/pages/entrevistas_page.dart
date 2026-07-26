// Atomic Design (Página): Placeholder navegable de preparación de entrevistas.

import 'package:flutter/material.dart';
import '../organisms/placeholder_destino.dart';

class EntrevistasPage extends StatelessWidget {
  const EntrevistasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDestino(
      titulo: 'Entrevistas',
      detalle:
          'Destino en construcción: la preparación de entrevistas llega en fases posteriores al Módulo 1.',
    );
  }
}
