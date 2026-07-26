// Pruebas de widget de la pantalla de login (issue #1).
//
// Reemplazan la plantilla del contador de Flutter, que aseveraba sobre '0', '1'
// e Icons.add: widgets que esta app nunca tuvo.
//
// Los signals de auth_state son globales al proceso, así que cada prueba los
// reinicia en setUp para no heredar el estado de la anterior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/main.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';

/// Amplía la ventana de prueba: el formulario completo no cabe en los 800x600
/// por defecto y el desborde ensuciaría las aserciones.
void _ampliarVentana(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    isAuthenticated.value = false;
    authLoading.value = false;
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

    expect(
      find.widgetWithText(ElevatedButton, 'Iniciar con Google'),
      findsOneWidget,
    );
  });

  testWidgets('con authLoading activo se muestra el indicador en lugar del formulario',
      (WidgetTester tester) async {
    _ampliarVentana(tester);
    authLoading.value = true;

    await tester.pumpWidget(const MyApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Iniciar con Google'),
      findsNothing,
    );
  });
}
