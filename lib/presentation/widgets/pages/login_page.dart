// Atomic Design (Página): Estructura principal que une organismos y maneja
// la inyección de dependencias y el estado global o de la vista.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../organisms/login_form.dart';
import '../../utils/constants.dart';
import '../../state/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El fondo y los estilos de texto vienen del tema (AppTheme).
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Encabezado: nivel headlineLg de la escala del design system
                  Text(
                    'Bienvenido',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 3),

                  // Observador reactivo de signals (Watch).
                  // signals_flutter 7.1 deprecó Watch a favor de SignalBuilder,
                  // pero §3 del handoff fija Watch como decisión cerrada. Se
                  // suprime el aviso para cumplir el AC2 del #1 (analyze sin
                  // issues) sin cambiar la decisión; anotado en la bitácora §9.
                  // ignore: deprecated_member_use
                  Watch((context) {
                    if (authLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return LoginForm(
                      onLogin: () {
                        // Aquí llamarías al caso de uso inyectado con getIt
                      },
                      onLoginWithGoogle: () async {
                        // Ejemplo simulado usando signals:
                        authLoading.value = true;

                        // Simulamos una petición de red de 2 segundos
                        await Future.delayed(const Duration(seconds: 2));

                        authLoading.value = false;
                        isAuthenticated.value = true;

                        // El flujo del Módulo 1 sigue en el onboarding. Los
                        // route guards reales llegan con el #9.
                        if (context.mounted) {
                          context.go('/onboarding');
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
