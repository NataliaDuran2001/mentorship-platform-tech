// Capa Core (Router): definición de rutas con go_router y wiring del shell
// responsivo. Login y onboarding viven fuera del ShellRoute, sin nav visible.
// Los route guards de sesión llegan con la autenticación real (#9).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_branding.dart';
import '../../presentation/widgets/organisms/app_shell.dart';
import '../../presentation/widgets/pages/chat_page.dart';
import '../../presentation/widgets/pages/dashboard_page.dart';
import '../../presentation/widgets/pages/entrevistas_page.dart';
import '../../presentation/widgets/pages/login_page.dart';
import '../../presentation/widgets/pages/logica_page.dart';
import '../../presentation/widgets/pages/onboarding_page.dart';
import '../../presentation/widgets/pages/perfil_page.dart';

/// Destinos del shell y sus rutas, en el mismo orden. Perfil no ocupa slot
/// del bottom nav: en ≤768 se llega por el ícono del AppBar (§9 del handoff).
const _destinos = <AppDestination>[
  AppDestination(label: 'Dashboard', icon: Icons.space_dashboard_outlined),
  AppDestination(label: 'Chat', icon: Icons.chat_bubble_outline),
  AppDestination(label: 'Lógica', icon: Icons.psychology_outlined),
  AppDestination(label: 'Entrevistas', icon: Icons.record_voice_over_outlined),
  AppDestination(
    label: 'Perfil',
    icon: Icons.person_outline,
    enBottomNav: false,
  ),
];

const _rutas = <String>[
  '/dashboard',
  '/chat',
  '/logica',
  '/entrevistas',
  '/perfil',
];

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Raíz: alias del dashboard para que recargar en '/' no dé 404.
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),

      // Fuera del shell: sin nav visible.
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),

      ShellRoute(
        builder: (context, state, child) {
          final indice = _rutas.indexOf(state.uri.path);
          return AppShell(
            title: AppBranding.name,
            destinations: _destinos,
            // Si la ruta no está en la lista (no debería pasar dentro del
            // shell), se cae al dashboard para no romper el nav.
            selectedIndex: indice < 0 ? 0 : indice,
            onDestinationSelected: (i) => context.go(_rutas[i]),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
          GoRoute(path: '/logica', builder: (_, __) => const LogicaPage()),
          GoRoute(
            path: '/entrevistas',
            builder: (_, __) => const EntrevistasPage(),
          ),
          GoRoute(path: '/perfil', builder: (_, __) => const PerfilPage()),
        ],
      ),
    ],
  );
}
