// Capa Core (Router): definición de rutas con go_router, route guards de
// sesión y wiring del shell responsivo. Login, registro y onboarding viven
// fuera del ShellRoute, sin nav visible.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../config/app_branding.dart';
import '../../presentation/state/auth_actions.dart';
import '../../presentation/state/auth_state.dart';
import '../../presentation/widgets/organisms/app_shell.dart';
import '../../presentation/widgets/pages/chat_page.dart';
import '../../presentation/widgets/pages/dashboard_page.dart';
import '../../presentation/widgets/pages/entrevistas_page.dart';
import '../../presentation/widgets/pages/login_page.dart';
import '../../presentation/widgets/pages/logica_page.dart';
import '../../presentation/widgets/pages/onboarding_page.dart';
import '../../presentation/widgets/pages/perfil_page.dart';
import '../../presentation/widgets/pages/sign_up_page.dart';

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

/// Rutas accesibles sin sesión.
const _rutasPublicas = <String>{'/login', '/registro'};

/// La única ruta permitida con sesión y onboarding incompleto.
const _rutaOnboarding = '/onboarding';

class AppRouter {
  AppRouter._();

  /// Vuelve a evaluar los guards cuando cambia la sesión o el perfil.
  ///
  /// go_router necesita un Listenable y los signals no lo son: este puente
  /// convierte un `effect` en notificaciones. Es lo que hace que entrar,
  /// terminar el onboarding o cerrar sesión redirijan sin que ninguna pantalla
  /// llame a `context.go()` a mano.
  static final _SignalsRefreshListenable _refresco =
      _SignalsRefreshListenable();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _refresco,
    redirect: _guard,
    routes: [
      // Raíz: alias del dashboard para que recargar en '/' no dé 404.
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),

      // Fuera del shell: sin nav visible.
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/registro', builder: (_, __) => const SignUpPage()),
      GoRoute(
        path: _rutaOnboarding,
        builder: (_, __) => const OnboardingPage(),
      ),

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
            onLogout: signOut,
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

  /// Los tres casos del issue #9:
  ///
  /// 1. Sin sesión → `/login`.
  /// 2. Con sesión y onboarding incompleto → `/onboarding`.
  /// 3. Con sesión y onboarding completo → `/dashboard`.
  ///
  /// Vale también para el acceso directo por URL: el guard corre en cada
  /// navegación, incluida la primera, así que escribir `/dashboard` en la barra
  /// del navegador sin sesión termina en el login.
  ///
  /// «Onboarding completo» se pregunta a `hasCompletedOnboarding`, que exige
  /// `track` además de la marca de tiempo. Es lo que garantiza que ningún camino
  /// llegue al dashboard con `track_id` nulo (política del #14).
  static String? _guard(BuildContext context, GoRouterState state) {
    final destino = state.matchedLocation;
    final esPublica = _rutasPublicas.contains(destino);

    if (!isAuthenticated.value) {
      return esPublica ? null : '/login';
    }

    if (!hasCompletedOnboarding.value) {
      return destino == _rutaOnboarding ? null : _rutaOnboarding;
    }

    // Con el onboarding terminado, login, registro y onboarding ya no aplican.
    if (esPublica || destino == _rutaOnboarding) return '/dashboard';
    return null;
  }
}

/// Puente entre los signals de autenticación y el `refreshListenable` de
/// go_router.
class _SignalsRefreshListenable extends ChangeNotifier {
  _SignalsRefreshListenable() {
    _cancelar = effect(() {
      // Leerlos dentro del effect es lo que los suscribe.
      currentSession.value;
      currentProfile.value;
      notifyListeners();
    });
  }

  late final void Function() _cancelar;

  @override
  void dispose() {
    _cancelar();
    super.dispose();
  }
}
