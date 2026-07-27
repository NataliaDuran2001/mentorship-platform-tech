// Atomic Design (Organismo): Sección funcional reutilizable.
// Encuadre común de las pantallas de autenticación: título, ancho legible y
// scroll. Lo comparten login y registro para que no se vean distintas.

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El fondo y los estilos de texto vienen del tema (AppTheme).
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxReadableWidth / 2,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nivel headlineLg de la escala del design system.
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(
                      height: AppConstants.defaultPadding * 3,
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
