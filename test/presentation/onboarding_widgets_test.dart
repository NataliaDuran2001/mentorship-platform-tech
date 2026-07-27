// Pruebas de widget de los átomos y moléculas del onboarding (issue #10).
//
// El AC5 pide dos cosas: que el callback de selección dispare y que el estado
// visual `selected` se aplique. Lo segundo se verifica leyendo la decoración
// real del widget, no una captura: los valores tienen que coincidir con
// `descubre_tu_ruta_onboarding/code.html` (AC3).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/presentation/utils/app_colors.dart';
import 'package:aspire_app/presentation/utils/constants.dart';
import 'package:aspire_app/presentation/widgets/atoms/app_progress_bar.dart';
import 'package:aspire_app/presentation/widgets/atoms/app_radio.dart';
import 'package:aspire_app/presentation/widgets/atoms/icon_tile.dart';
import 'package:aspire_app/presentation/widgets/atoms/step_counter_label.dart';
import 'package:aspire_app/presentation/widgets/molecules/goal_radio_row.dart';
import 'package:aspire_app/presentation/widgets/molecules/onboarding_footer.dart';
import 'package:aspire_app/presentation/widgets/molecules/option_card_tile.dart';
import 'package:aspire_app/presentation/widgets/molecules/track_card.dart';

/// Monta un widget suelto con el tema real de la app.
Future<void> _montar(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 600, child: child))),
    ),
  );
}

/// Decoración de la tarjeta, no la del recuadro del ícono.
///
/// Las dos son AnimatedContainer; la de la tarjeta es la única con borde.
BoxDecoration _decoracionDeTarjeta(WidgetTester tester) {
  return tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((c) => c.decoration! as BoxDecoration)
      .firstWhere((d) => d.border != null);
}

void main() {
  group('OptionCardTile', () {
    testWidgets('el tap dispara el callback de selección', (tester) async {
      var toques = 0;

      await _montar(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Estudiante / Autodidacta',
          description: 'Estoy aprendiendo las bases y busco mi primer empleo.',
          isSelected: false,
          onTap: () => toques++,
        ),
      );

      await tester.tap(find.text('Estudiante / Autodidacta'));
      await tester.pumpAndSettle();

      expect(toques, 1);
    });

    testWidgets('sin seleccionar: borde outlineVariant y sin anillo',
        (tester) async {
      await _montar(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Estudiante',
          isSelected: false,
          onTap: () {},
        ),
      );

      final decoracion = _decoracionDeTarjeta(tester);

      expect(decoracion.border, isA<Border>());
      expect((decoracion.border! as Border).top.color,
          AppColors.outlineVariant);
      expect(decoracion.color, Colors.transparent);
      expect(decoracion.boxShadow, isNull);
    });

    testWidgets(
        'seleccionado: borde primary, fondo primary al 8% y anillo de 1px',
        (tester) async {
      await _montar(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Estudiante',
          isSelected: true,
          onTap: () {},
        ),
      );

      final decoracion = _decoracionDeTarjeta(tester);

      // Borde #674BB5 del prototipo, vía token.
      expect((decoracion.border! as Border).top.color, AppColors.primary);
      // rgba(103, 75, 181, 0.08)
      expect(decoracion.color, AppColors.primary.withValues(alpha: 0.08));
      // box-shadow: 0 0 0 1px #674bb5
      expect(decoracion.boxShadow, hasLength(1));
      expect(decoracion.boxShadow!.first.color, AppColors.primary);
      expect(decoracion.boxShadow!.first.spreadRadius,
          AppConstants.borderWidth);
      expect(decoracion.boxShadow!.first.blurRadius, 0);
    });

    testWidgets('seleccionado resalta el recuadro del ícono', (tester) async {
      await _montar(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Estudiante',
          isSelected: true,
          onTap: () {},
        ),
      );

      expect(
        tester.widget<IconTile>(find.byType(IconTile)).isHighlighted,
        isTrue,
      );
    });

    testWidgets('la descripción es opcional', (tester) async {
      await _montar(
        tester,
        OptionCardTile(
          icon: Icons.web,
          title: 'Frontend',
          isSelected: false,
          onTap: () {},
        ),
      );

      expect(find.text('Frontend'), findsOneWidget);
      // Solo el título: la card del paso 2 no lleva segunda línea.
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('TrackCard', () {
    testWidgets('el tap dispara el callback', (tester) async {
      var toques = 0;

      await _montar(
        tester,
        TrackCard(
          icon: Icons.storage,
          title: 'Back-end',
          description: 'Diseñar la lógica detrás de escena.',
          isSelected: false,
          onTap: () => toques++,
        ),
      );

      await tester.tap(find.text('Back-end'));
      await tester.pumpAndSettle();

      expect(toques, 1);
    });

    testWidgets('seleccionado aplica el mismo estado visual que la opción',
        (tester) async {
      await _montar(
        tester,
        TrackCard(
          icon: Icons.storage,
          title: 'Back-end',
          isSelected: true,
          onTap: () {},
        ),
      );

      final decoracion = _decoracionDeTarjeta(tester);

      expect((decoracion.border! as Border).top.color, AppColors.primary);
      expect(decoracion.color, AppColors.primary.withValues(alpha: 0.08));
      expect(decoracion.boxShadow, hasLength(1));
    });
  });

  group('GoalRadioRow y AppRadio', () {
    testWidgets('la fila completa es clickeable, no solo el círculo',
        (tester) async {
      var toques = 0;

      await _montar(
        tester,
        GoalRadioRow(
          label: 'Conseguir mi primer empleo profesional',
          isSelected: false,
          onTap: () => toques++,
        ),
      );

      // Toca la etiqueta, en el extremo opuesto al círculo.
      await tester.tap(find.text('Conseguir mi primer empleo profesional'));
      await tester.pumpAndSettle();

      expect(toques, 1);
    });

    testWidgets('sin seleccionar el punto está en opacidad 0', (tester) async {
      await _montar(tester, const AppRadio(isSelected: false));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });

    testWidgets('seleccionado el punto está en opacidad 1', (tester) async {
      await _montar(tester, const AppRadio(isSelected: true));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
    });
  });

  group('OnboardingFooter', () {
    testWidgets('«Continuar» dispara su callback', (tester) async {
      var toques = 0;

      await _montar(tester, OnboardingFooter(onContinue: () => toques++));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(toques, 1);
    });

    testWidgets('onContinue en null deshabilita el botón', (tester) async {
      await _montar(tester, const OnboardingFooter(onContinue: null));

      final boton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );

      expect(boton.onPressed, isNull);
    });

    testWidgets('«Omitir» se puede ocultar por completo, como en el paso 2',
        (tester) async {
      await _montar(
        tester,
        OnboardingFooter(onContinue: () {}, showSkip: false),
      );

      expect(find.text('Omitir'), findsNothing);
      expect(find.text('Regresar'), findsOneWidget);
    });

    testWidgets('«Regresar» oculto conserva su espacio', (tester) async {
      await _montar(
        tester,
        OnboardingFooter(onContinue: () {}, showBack: false),
      );

      // Sigue en el árbol (maintainSize) pero no es accionable.
      expect(find.text('Regresar'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Regresar'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('la etiqueta de «Continuar» se puede cambiar', (tester) async {
      await _montar(
        tester,
        OnboardingFooter(
          onContinue: () {},
          continueLabel: 'Entrar al Dashboard',
        ),
      );

      expect(find.text('Entrar al Dashboard'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
    });
  });

  group('Átomos sin estado propio', () {
    testWidgets('StepCounterLabel rinde el total que recibe, en mayúsculas',
        (tester) async {
      await _montar(
        tester,
        const StepCounterLabel(currentStep: 2, totalSteps: 5),
      );

      expect(find.text('PASO 2 DE 5'), findsOneWidget);
    });

    testWidgets('AppProgressBar anima hasta la fracción recibida',
        (tester) async {
      await _montar(tester, const AppProgressBar(value: 0.4));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.4, 0.001),
      );
    });

    testWidgets('AppProgressBar recorta valores fuera de rango',
        (tester) async {
      await _montar(tester, const AppProgressBar(value: 1.8));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        1.0,
      );
    });
  });
}
