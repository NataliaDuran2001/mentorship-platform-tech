// Tests of the card that closes a lab: the fraction, the tier it reads as, and
// the list of what to go back to — which must only appear when there is
// something to go back to.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/lab_score.dart';
import 'package:aspire_app/presentation/widgets/organisms/lab_score_card.dart';

Future<void> _pump(
  WidgetTester tester,
  LabScore score, {
  List<String> missed = const <String>[],
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LabScoreCard(score: score, missedQuestions: missed),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the score as a fraction, not a bare percentage', (
    tester,
  ) async {
    await _pump(tester, const LabScore(correct: 4, total: 5));

    expect(find.text('4'), findsOneWidget);
    expect(find.text(' / 5'), findsOneWidget);
    expect(find.textContaining('first try'), findsOneWidget);
  });

  testWidgets('a clean run is congratulated as a perfect one', (tester) async {
    await _pump(tester, const LabScore(correct: 3, total: 3));

    expect(find.text('Perfect run'), findsOneWidget);
    // Nothing was retried, so nothing is offered up for review.
    expect(find.text('Worth another look'), findsNothing);
  });

  testWidgets('one slip reads as strong work', (tester) async {
    await _pump(tester, const LabScore(correct: 4, total: 5));

    expect(find.text('Strong work'), findsOneWidget);
  });

  testWidgets('a weak run is encouraged, not failed', (tester) async {
    await _pump(tester, const LabScore(correct: 1, total: 5));

    // Reaching this card at all means the section was finished, and the copy
    // has to lead with that rather than with the deficit.
    expect(find.text('You made it through'), findsOneWidget);
    expect(find.textContaining('finished it anyway'), findsOneWidget);
  });

  testWidgets('the explanations are counted so the denominator adds up', (
    tester,
  ) async {
    // What the learner lived: three screens. What is scored: two of them.
    await _pump(tester, const LabScore(correct: 0, total: 2, concepts: 1));

    expect(find.text(' / 2'), findsOneWidget);
    expect(find.textContaining('1 concept read'), findsOneWidget);
    expect(find.textContaining('not scored'), findsOneWidget);
  });

  testWidgets('a lab with no explanations does not mention them', (
    tester,
  ) async {
    await _pump(tester, const LabScore(correct: 2, total: 3));

    expect(find.textContaining('concept'), findsNothing);
  });

  testWidgets('the retried challenges are named', (tester) async {
    await _pump(
      tester,
      const LabScore(correct: 1, total: 3),
      missed: const ['Which language owns color?', 'What closes a tag?'],
    );

    expect(find.text('Worth another look'), findsOneWidget);
    expect(find.text('Which language owns color?'), findsOneWidget);
    expect(find.text('What closes a tag?'), findsOneWidget);
  });
}
