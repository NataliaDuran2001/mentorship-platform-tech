// Atomic Design (Página): Placeholder navegable del chat con la mentora IA.

import 'package:flutter/material.dart';
import '../organisms/placeholder_destino.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDestino(
      titulo: 'Chat',
      detalle:
          'Destino en construcción: el chat con la mentora de IA llega en fases posteriores al Módulo 1.',
    );
  }
}
