// Atomic Design (Página): Placeholder navegable del dashboard. El contenido
// real (roadmap y progreso) llega con el Módulo 1 (E1).

import 'package:flutter/material.dart';
import '../organisms/placeholder_destino.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDestino(
      titulo: 'Dashboard',
      detalle:
          'Destino en construcción: el resumen del roadmap y el progreso llegan con el Módulo 1 (E1).',
    );
  }
}
