// Pruebas de la rama del cuestionario guía (issue #12).
//
// El AC3 es el que más importa: la regla de decisión tiene que salir de
// RecommendTrackUseCase y no de un `if` en la UI. Se verifica registrando qué
// recibe el caso de uso y comprobando que su salida es la que se muestra,
// incluso cuando esa salida contradice la mayoría aparente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/track_recommendation.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/recommend_track_usecase.dart';
import 'package:aspire_app/domain/usecases/submit_onboarding_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/onboarding_actions.dart';
import 'package:aspire_app/presentation/state/onboarding_state.dart';
import 'package:aspire_app/presentation/utils/onboarding_labels.dart';
import 'package:aspire_app/presentation/utils/onboarding_quiz.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';

/// Registra cada respuesta guardada, para verificar la persistencia del AC5.
class SpyOnboardingRepository implements OnboardingRepository {
  final List<OnboardingAnswer> guardadas = [];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {
    guardadas.add(answer);
  }

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async => guardadas;

  @override
  Future<UserProfile?> loadProfile() async => null;

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    return UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      track: track,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );
  }
}

/// Caso de uso falso: devuelve lo que se le diga y anota qué recibió.
///
/// Sirve para probar que la UI **no** decide: si el widget tuviera su propia
/// regla, el resultado no coincidiría con lo que este doble devuelve.
class FakeRecommendTrackUseCase implements RecommendTrackUseCase {
  FakeRecommendTrackUseCase(this.resultado);

  TrackRecommendation resultado;
  List<OnboardingAnswer>? recibidas;

  @override
  TrackRecommendation call(List<OnboardingAnswer> answers) {
    recibidas = answers;
    return resultado;
  }
}

Future<void> _montar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
}

Future<void> _esperar(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 600));

/// Responde las 3 preguntas votando siempre al mismo track.
///
/// Busca la opción por su afinidad y no por un texto fijo: solo la primera
/// pregunta usa los nombres de los tracks como etiquetas.
Future<void> _responderTodo(WidgetTester tester, RoadmapTrack track) async {
  for (final pregunta in preguntasDelCuestionario) {
    final opcion = pregunta.options.firstWhere((o) => o.affinity == track);
    await tester.tap(find.text(opcion.label));
    await _esperar(tester);
  }
}

void main() {
  late SpyOnboardingRepository repo;
  late FakeRecommendTrackUseCase recomendador;

  setUp(() {
    repo = SpyOnboardingRepository();
    recomendador = FakeRecommendTrackUseCase(
      const TrackRecommendation(
        track: RoadmapTrack.backend,
        scores: {
          RoadmapTrack.frontend: 0,
          RoadmapTrack.backend: 3,
          RoadmapTrack.infrastructure: 0,
        },
        wasTie: false,
      ),
    );

    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));
    overrideDependency<RecommendTrackUseCase>(recomendador);

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;

    // Entra a la rama guiada: es lo que hace «Aún no lo sé» en el paso 2.
    usesGuidedQuiz.value = true;
    currentStepIndex.value = 2;
  });

  tearDown(cancelOnboardingTimers);

  testWidgets('es alcanzable desde el paso 2 y el contador dice «de 5»',
      (tester) async {
    resetOnboarding();
    currentStepIndex.value = 1;
    await _montar(tester);

    await tester.tap(find.text(opcionNoLoSe.label));
    await _esperar(tester);

    expect(currentStep.value, OnboardingStepId.quiz);
    expect(find.text('PASO 3 DE 5'), findsOneWidget);
    expect(
      find.text('¿Qué tipo de problemas te entusiasma más resolver?'),
      findsOneWidget,
    );
  });

  testWidgets('ofrece los 3 tracks decididos, sin Mobile ni UI/UX',
      (tester) async {
    await _montar(tester);

    expect(find.text('Front-end'), findsOneWidget);
    expect(find.text('Back-end'), findsOneWidget);
    expect(find.text('Infraestructura'), findsOneWidget);
    expect(find.text('Mobile'), findsNothing);
    expect(find.text('UI / UX Design'), findsNothing);
  });

  testWidgets('recorre las preguntas y muestra el número de cada una',
      (tester) async {
    await _montar(tester);

    expect(find.textContaining('Pregunta 1 de 3'), findsOneWidget);

    await tester.tap(find.text('Front-end'));
    await _esperar(tester);

    expect(find.textContaining('Pregunta 2 de 3'), findsOneWidget);
    // Sigue siendo el paso 3 de 5: el cuestionario es un paso, no tres.
    expect(find.text('PASO 3 DE 5'), findsOneWidget);
  });

  testWidgets('la recomendación sale del caso de uso, no del widget',
      (tester) async {
    await _montar(tester);

    // Vota 3 veces a Front-end, pero el caso de uso devuelve Back-end.
    await _responderTodo(tester, RoadmapTrack.frontend);

    expect(quizShowingResult.value, isTrue);
    // Lo que se muestra es lo que dijo el caso de uso, no la mayoría aparente.
    expect(find.text('Encontramos tu ruta'), findsOneWidget);
    expect(find.text('Back-end'), findsWidgets);

    // Y recibió las 3 respuestas con sus claves quiz_N.
    expect(recomendador.recibidas, hasLength(3));
    expect(
      recomendador.recibidas!.map((a) => a.stepKey),
      containsAll(<String>['quiz_1', 'quiz_2', 'quiz_3']),
    );
    expect(
      recomendador.recibidas!.every((a) => a.value == 'frontend'),
      isTrue,
    );
  });

  testWidgets('cada respuesta queda persistida con su clave quiz_N',
      (tester) async {
    await _montar(tester);
    await _responderTodo(tester, RoadmapTrack.infrastructure);

    final claves = repo.guardadas.map((a) => a.stepKey).toList();
    expect(claves, ['quiz_1', 'quiz_2', 'quiz_3']);
    expect(
      repo.guardadas.every((a) => a.value == 'infrastructure'),
      isTrue,
    );
  });

  testWidgets('el resultado exige confirmación: el track no se asigna solo',
      (tester) async {
    await _montar(tester);
    await _responderTodo(tester, RoadmapTrack.frontend);

    // Con el resultado a la vista todavía no hay track asignado.
    expect(selectedTrack.value, isNull);

    await tester.tap(find.text('Confirmar esta ruta'));
    await tester.pumpAndSettle();

    expect(selectedTrack.value, RoadmapTrack.backend);
    // Y el flujo sigue en el paso de la meta, con el contador todavía en 5.
    expect(currentStep.value, OnboardingStepId.goal);
    expect(totalSteps.value, 5);
    expect(find.text('¿Cuál es tu meta principal?'), findsOneWidget);
    expect(find.text('PASO 4 DE 5'), findsOneWidget);
  });

  testWidgets('se puede corregir la recomendación a mano', (tester) async {
    await _montar(tester);
    await _responderTodo(tester, RoadmapTrack.frontend);

    // El recomendado es Back-end; se elige Infraestructura en su lugar.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Infraestructura'));
    await tester.pumpAndSettle();

    expect(selectedTrack.value, RoadmapTrack.infrastructure);
    expect(currentStep.value, OnboardingStepId.goal);
    // La corrección también se persiste, con la clave del paso del track.
    expect(
      repo.guardadas.last.stepKey,
      'track',
    );
    expect(repo.guardadas.last.value, 'infrastructure');
  });

  testWidgets('un empate se avisa en vez de presentarse como concluyente',
      (tester) async {
    recomendador.resultado = const TrackRecommendation(
      track: RoadmapTrack.frontend,
      scores: {
        RoadmapTrack.frontend: 1,
        RoadmapTrack.backend: 1,
        RoadmapTrack.infrastructure: 1,
      },
      wasTie: true,
    );

    await _montar(tester);
    await _responderTodo(tester, RoadmapTrack.frontend);

    expect(find.textContaining('Estuvo parejo con otra ruta'), findsOneWidget);
  });

  testWidgets('se puede volver a responder el cuestionario', (tester) async {
    await _montar(tester);
    await _responderTodo(tester, RoadmapTrack.frontend);

    await tester.tap(find.text('Volver a responder el cuestionario'));
    await tester.pumpAndSettle();

    expect(quizShowingResult.value, isFalse);
    expect(quizAnswers.value, isEmpty);
    expect(find.textContaining('Pregunta 1 de 3'), findsOneWidget);
  });

  testWidgets('«Anterior» vuelve pregunta por pregunta y luego sale del '
      'cuestionario', (tester) async {
    await _montar(tester);

    await tester.tap(find.text('Front-end'));
    await _esperar(tester);
    expect(find.textContaining('Pregunta 2 de 3'), findsOneWidget);

    await tester.tap(find.text('Regresar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pregunta 1 de 3'), findsOneWidget);

    // Desde la primera, «Regresar» sale de la rama guiada.
    await tester.tap(find.text('Regresar'));
    await tester.pumpAndSettle();

    expect(currentStep.value, OnboardingStepId.track);
    expect(usesGuidedQuiz.value, isFalse);
    expect(totalSteps.value, 4);
  });

  testWidgets('«Continuar» está deshabilitado hasta responder la pregunta',
      (tester) async {
    await _montar(tester);

    final boton = find.widgetWithText(ElevatedButton, 'Continuar');
    expect(tester.widget<ElevatedButton>(boton).onPressed, isNull);

    await tester.tap(find.text('Back-end'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(boton).onPressed, isNotNull);
    await _esperar(tester);
  });

  testWidgets('«Omitir» no existe en el cuestionario', (tester) async {
    await _montar(tester);
    expect(find.text('Omitir'), findsNothing);
  });
}
