// Atomic Design (Página): Placeholder navegable de la práctica de lógica.

import 'package:flutter/material.dart';
import '../organisms/placeholder_destino.dart';

class LogicaPage extends StatelessWidget {
  const LogicaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDestino(
      titulo: 'Lógica',
      detalle:
          'Destino en construcción: la práctica de lógica llega con el árbol de tópicos del Módulo 1 (E1).',
    );
  }
}
