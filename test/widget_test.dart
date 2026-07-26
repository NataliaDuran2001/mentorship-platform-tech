// Pruebas de widget de la app (issues #1 y #5).
//
// Los signals de auth_state son globales al proceso y el GoRouter de
// AppRouter es una instancia única, así que cada prueba reinicia ambos en
// setUp para no heredar el estado de la anterior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/router/app_router.dart';
import 'package:aspire_app/main.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/widgets/pages/chat_page.dart';
import 'package:aspire_app/presentation/widgets/pages/dashboard_page.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';

/// Fija el tamaño lógico de la ventana de prueba (devicePixelRatio 1).
void _fijarVentana(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Amplía la ventana: el formulario completo no cabe en los 800x600 por
/// defecto y el desborde ensuciaría las aserciones.
void _ampliarVentana(WidgetTester tester) =>
    _fijarVentana(tester, const Size(1200, 2000));

void main() {
  setUp(() {
    isAuthenticated.value = false;
    authLoading.value = false;
    AppRouter.router.go('/login');
  });

  testWidgets('LoginPage monta y renderiza sus textos en español',
      (WidgetTester tester) async {
    _ampliarVentana(tester);

    await tester.pumpWidget(const MyApp());

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
  });

  testWidgets('el botón de inicio con Google está presente',
      (WidgetTester tester) async {
    _ampliarVentana(tester);

    await tester.pumpWidget(const MyApp());

    // Desde el issue #2 la variante secundaria de CustomButton es un
    // OutlinedButton temado (antes ElevatedButton con estilo inline).
    expect(
      find.widgetWithText(OutlinedButton, 'Iniciar con Google'),
      findsOneWidget,
    );
  });

  testWidgets(
      'con authLoading activo se muestra el indicador en lugar del formulario',
      (WidgetTester tester) async {
    _ampliarVentana(tester);
    authLoading.value = true;

    await tester.pumpWidget(const MyApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Iniciar con Google'),
      findsNothing,
    );
  });

  testWidgets(
      'el login simulado navega al onboarding, que no muestra nav (issue #5)',
      (WidgetTester tester) async {
    _ampliarVentana(tester);

    await tester.pumpWidget(const MyApp());

    // El login vive fuera del shell: sin bottom nav ni sidebar.
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Iniciar con Google'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // La "petición" simulada dura 2 segundos.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(
      AppRouter.router.routerDelegate.currentConfiguration.uri.path,
      '/onboarding',
    );
    // El onboarding también vive fuera del shell.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('se navega entre los destinos del shell y la URL lo refleja',
      (WidgetTester tester) async {
    _ampliarVentana(tester); // 1200 lógicos: modo escritorio con sidebar

    AppRouter.router.go('/dashboard');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(DashboardPage), findsOneWidget);

    // En escritorio el nav es la sidebar; tocar un ítem cambia ruta y URL.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatPage), findsOneWidget);
    expect(
      AppRouter.router.routerDelegate.currentConfiguration.uri.path,
      '/chat',
    );
  });

  testWidgets('el shell cambia de forma en los breakpoints 480 y 768',
      (WidgetTester tester) async {
    // Móvil (≤480): bottom nav, sin drawer ni sidebar.
    _fijarVentana(tester, const Size(440, 900));
    AppRouter.router.go('/dashboard');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);

    // Rango intermedio (481–768): bottom nav + drawer (hamburguesa).
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Escritorio (>768): sidebar fija, sin bottom nav ni hamburguesa.
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.text('Dashboard'), findsWidgets); // sidebar + placeholder
  });
}
