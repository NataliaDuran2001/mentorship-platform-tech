// Atomic Design (Página): Placeholder navegable del perfil de la usuaria.

import 'package:flutter/material.dart';
import '../organisms/placeholder_destino.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderDestino(
      titulo: 'Perfil',
      detalle:
          'Destino en construcción: la gestión del perfil llega con la autenticación real (#9).',
    );
  }
}
