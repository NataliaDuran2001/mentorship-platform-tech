// Widget tests of the onboarding atoms and molecules (issue #10).
//
// AC5 asks for two things: that the selection callback fires and that the
// `selected` visual state is applied. The second one is verified by reading
// the widget's real decoration, not a screenshot: the values have to match
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

/// Mounts a standalone widget with the app's real theme.
Future<void> _mount(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 600, child: child))),
    ),
  );
}

/// The card's decoration, not the one of the icon box.
///
/// Both are AnimatedContainer; the card's is the only one with a border.
BoxDecoration _cardDecoration(WidgetTester tester) {
  return tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((c) => c.decoration! as BoxDecoration)
      .firstWhere((d) => d.border != null);
}

void main() {
  group('OptionCardTile', () {
    testWidgets('the tap fires the selection callback', (tester) async {
      var taps = 0;

      await _mount(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Student / Self-taught',
          description: 'I am learning the basics and looking for my first job.',
          isSelected: false,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.text('Student / Self-taught'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('unselected: outlineVariant border and no ring',
        (tester) async {
      await _mount(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Student',
          isSelected: false,
          onTap: () {},
        ),
      );

      final decoration = _cardDecoration(tester);

      expect(decoration.border, isA<Border>());
      expect((decoration.border! as Border).top.color,
          AppColors.outlineVariant);
      expect(decoration.color, Colors.transparent);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets(
        'selected: primary border, primary background at 8% and a 1px ring',
        (tester) async {
      await _mount(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Student',
          isSelected: true,
          onTap: () {},
        ),
      );

      final decoration = _cardDecoration(tester);

      // The prototype's #674BB5 border, through the token.
      expect((decoration.border! as Border).top.color, AppColors.primary);
      // rgba(103, 75, 181, 0.08)
      expect(decoration.color, AppColors.primary.withValues(alpha: 0.08));
      // box-shadow: 0 0 0 1px #674bb5
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.first.color, AppColors.primary);
      expect(decoration.boxShadow!.first.spreadRadius,
          AppConstants.borderWidth);
      expect(decoration.boxShadow!.first.blurRadius, 0);
    });

    testWidgets('selected highlights the icon box', (tester) async {
      await _mount(
        tester,
        OptionCardTile(
          icon: Icons.school,
          title: 'Student',
          isSelected: true,
          onTap: () {},
        ),
      );

      expect(
        tester.widget<IconTile>(find.byType(IconTile)).isHighlighted,
        isTrue,
      );
    });

    testWidgets('the description is optional', (tester) async {
      await _mount(
        tester,
        OptionCardTile(
          icon: Icons.web,
          title: 'Frontend',
          isSelected: false,
          onTap: () {},
        ),
      );

      expect(find.text('Frontend'), findsOneWidget);
      // Only the title: the step 2 card has no second line.
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('TrackCard', () {
    testWidgets('the tap fires the callback', (tester) async {
      var taps = 0;

      await _mount(
        tester,
        TrackCard(
          icon: Icons.storage,
          title: 'Back-end',
          description: 'Design the logic behind the scenes.',
          isSelected: false,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.text('Back-end'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('selected applies the same visual state as the option',
        (tester) async {
      await _mount(
        tester,
        TrackCard(
          icon: Icons.storage,
          title: 'Back-end',
          isSelected: true,
          onTap: () {},
        ),
      );

      final decoration = _cardDecoration(tester);

      expect((decoration.border! as Border).top.color, AppColors.primary);
      expect(decoration.color, AppColors.primary.withValues(alpha: 0.08));
      expect(decoration.boxShadow, hasLength(1));
    });
  });

  group('GoalRadioRow and AppRadio', () {
    testWidgets('the whole row is clickable, not just the circle',
        (tester) async {
      var taps = 0;

      await _mount(
        tester,
        GoalRadioRow(
          label: 'Land my first professional job',
          isSelected: false,
          onTap: () => taps++,
        ),
      );

      // Taps the label, at the opposite end from the circle.
      await tester.tap(find.text('Land my first professional job'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('unselected, the dot is at opacity 0', (tester) async {
      await _mount(tester, const AppRadio(isSelected: false));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });

    testWidgets('selected, the dot is at opacity 1', (tester) async {
      await _mount(tester, const AppRadio(isSelected: true));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
    });
  });

  group('OnboardingFooter', () {
    testWidgets('"Continue" fires its callback', (tester) async {
      var taps = 0;

      await _mount(tester, OnboardingFooter(onContinue: () => taps++));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('onContinue set to null disables the button', (tester) async {
      await _mount(tester, const OnboardingFooter(onContinue: null));

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('"Skip" can be hidden entirely, like on step 2',
        (tester) async {
      await _mount(
        tester,
        OnboardingFooter(onContinue: () {}, showSkip: false),
      );

      expect(find.text('Skip'), findsNothing);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('a hidden "Back" keeps its space', (tester) async {
      await _mount(
        tester,
        OnboardingFooter(onContinue: () {}, showBack: false),
      );

      // It is still in the tree (maintainSize) but it is not actionable.
      expect(find.text('Back'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Back'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('the "Continue" label can be changed', (tester) async {
      await _mount(
        tester,
        OnboardingFooter(
          onContinue: () {},
          continueLabel: 'Go to Dashboard',
        ),
      );

      expect(find.text('Go to Dashboard'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });
  });

  group('Atoms with no state of their own', () {
    testWidgets('StepCounterLabel renders the total it receives, in uppercase',
        (tester) async {
      await _mount(
        tester,
        const StepCounterLabel(currentStep: 2, totalSteps: 5),
      );

      expect(find.text('STEP 2 OF 5'), findsOneWidget);
    });

    testWidgets('AppProgressBar animates up to the fraction it receives',
        (tester) async {
      await _mount(tester, const AppProgressBar(value: 0.4));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.4, 0.001),
      );
    });

    testWidgets('AppProgressBar clamps out-of-range values', (tester) async {
      await _mount(tester, const AppProgressBar(value: 1.8));
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
