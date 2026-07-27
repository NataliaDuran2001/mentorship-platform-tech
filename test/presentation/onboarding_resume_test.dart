// Pruebas de persistencia y reanudación del onboarding incompleto (issue #14).
//
// El repositorio falso emula el upsert real de `onboarding_answers`: clave
// (usuaria, `step_key`). Es lo que permite verificar que reanudar no acumula
// filas, que es el AC5.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
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

/// Repositorio en memoria con la misma semántica de upsert que la tabla.
class FakeOnboardingRepository implements OnboardingRepository {
  final Map<String, OnboardingAnswer> filas = <String, OnboardingAnswer>{};

  /// Cuántas escrituras se pidieron, para distinguir «actualizó» de «acumuló».
  int escrituras = 0;

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {
    escrituras++;
    // unique (user_id, step_key): la clave es el paso, no la fila.
    filas[answer.stepKey] = answer;
  }

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      filas.values.toList(growable: false);

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
      experienceLevel: experienceLevel,
      track: track,
      learningGoal: learningGoal,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );
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

/// Simula cerrar el navegador: se pierde todo el estado en memoria, queda solo
/// lo que hay en la base.
void _simularCerrarNavegador() {
  cancelOnboardingTimers();
  resetOnboarding();
}

void main() {
  late FakeOnboardingRepository repo;

  setUp(() {
    repo = FakeOnboardingRepository();
    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));
    overrideDependency<RecommendTrackUseCase>(const RecommendTrackUseCase());

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;
  });

  tearDown(cancelOnboardingTimers);

  group('Persistencia al seleccionar', () {
    testWidgets('cada respuesta queda guardada antes de completar el flujo',
        (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Junior Developer'));
      await _esperar(tester);

      // Ya está en la base, sin haber terminado el onboarding.
      expect(repo.filas.keys, contains('experience_level'));
      expect(repo.filas['experience_level']!.value, 'junior_developer');

      await tester.tap(find.text('Front-end'));
      await _esperar(tester);

      expect(repo.filas['track']!.value, 'frontend');

      await tester.tap(find.text('Conseguir mi primer empleo profesional'));
      await _esperar(tester);

      expect(repo.filas['goal']!.value, 'first_job');
      // Y el perfil todavía no se marcó como completo.
      expect(currentProfile.value, isNull);
    });

    testWidgets('«Aún no lo sé» también se guarda', (tester) async {
      currentStepIndex.value = 1;
      await _montar(tester);

      await tester.tap(find.text(opcionNoLoSe.label));
      await _esperar(tester);

      // Guardar «unknown» es lo que permite saber, al reanudar, que pidió la
      // guía y no que dejó el paso sin responder.
      expect(repo.filas['track']!.value, 'unknown');
    });

    testWidgets('cambiar una respuesta actualiza la fila, no acumula',
        (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Junior Developer'));
      await _esperar(tester);
      await tester.tap(find.text('Regresar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiando de Carrera'));
      await _esperar(tester);

      // Dos escrituras, una sola fila, con el valor nuevo.
      expect(repo.escrituras, 2);
      expect(
        repo.filas.keys.where((k) => k == 'experience_level'),
        hasLength(1),
      );
      expect(repo.filas['experience_level']!.value, 'career_switcher');
    });
  });

  group('Reanudación en la rama directa', () {
    testWidgets('volver reanuda en el paso 3, con los pasos 1 y 2 marcados',
        (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Junior Developer'));
      await _esperar(tester);
      await tester.tap(find.text('Front-end'));
      await _esperar(tester);

      // Está en el paso 3 y abandona.
      expect(find.text('¿Cuál es tu meta principal?'), findsOneWidget);
      _simularCerrarNavegador();

      // El estado en memoria se fue.
      expect(selectedLevel.value, isNull);
      expect(selectedTrack.value, isNull);

      await restoreOnboarding();
      await _montar(tester);
      await tester.pumpAndSettle();

      // Reanuda en el paso 3.
      expect(currentStep.value, OnboardingStepId.goal);
      expect(find.text('PASO 3 DE 4'), findsOneWidget);
      // Con los pasos 1 y 2 ya marcados.
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);
      expect(selectedTrack.value, RoadmapTrack.frontend);
    });

    testWidgets('al regresar se ven las selecciones previas marcadas',
        (tester) async {
      repo.filas['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.filas['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'backend');

      await restoreOnboarding();
      await _montar(tester);

      await tester.tap(find.text('Regresar'));
      await tester.pumpAndSettle();

      // El paso 2 muestra Back-end como elegido.
      expect(currentStep.value, OnboardingStepId.track);
      expect(selectedTrack.value, RoadmapTrack.backend);
    });

    testWidgets('sin nada guardado arranca en el paso 1', (tester) async {
      await restoreOnboarding();
      await _montar(tester);

      expect(currentStep.value, OnboardingStepId.level);
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
    });

    testWidgets('con todo respondido reanuda en el resumen', (tester) async {
      repo.filas['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.filas['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'backend');
      repo.filas['goal'] =
          const OnboardingAnswer(stepKey: 'goal', value: 'middle_level');

      await restoreOnboarding();
      await _montar(tester);

      expect(currentStep.value, OnboardingStepId.summary);
      expect(find.text('¡Todo listo!'), findsOneWidget);
    });
  });

  group('Omitir deja rastro', () {
    testWidgets('un paso omitido se guarda como «skipped»', (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(repo.filas['experience_level']!.value, 'skipped');
    });

    testWidgets('reanudar no devuelve a un paso que se omitió a propósito',
        (tester) async {
      await _montar(tester);

      // Omite el nivel y elige el track.
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Front-end'));
      await _esperar(tester);

      _simularCerrarNavegador();
      await restoreOnboarding();
      await _montar(tester);
      await tester.pumpAndSettle();

      // Retoma en la meta, no en el nivel que ya decidió saltear.
      expect(currentStep.value, OnboardingStepId.goal);
      expect(selectedLevel.value, isNull);
      expect(selectedTrack.value, RoadmapTrack.frontend);
    });
  });

  group('Reanudación en la rama del cuestionario guía', () {
    testWidgets('reanuda en la primera pregunta sin responder', (tester) async {
      repo.filas['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.filas['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'unknown');
      repo.filas['quiz_1'] =
          const OnboardingAnswer(stepKey: 'quiz_1', value: 'backend');

      await restoreOnboarding();
      await _montar(tester);

      // Rama guiada reconocida: 5 pasos.
      expect(usesGuidedQuiz.value, isTrue);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.quiz);
      // Con la 1 ya respondida, retoma en la 2.
      expect(find.textContaining('Pregunta 2 de 3'), findsOneWidget);
      expect(quizAnswers.value[1], RoadmapTrack.backend);
    });

    testWidgets('con las 3 respondidas y sin confirmar, vuelve al resultado',
        (tester) async {
      repo.filas['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.filas['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'unknown');
      for (final p in preguntasDelCuestionario) {
        repo.filas['quiz_${p.number}'] = OnboardingAnswer(
          stepKey: 'quiz_${p.number}',
          value: 'infrastructure',
        );
      }

      await restoreOnboarding();
      await _montar(tester);

      expect(quizShowingResult.value, isTrue);
      // La recomendación se recalcula con el caso de uso real: 3 votos a
      // infraestructura.
      expect(quizRecommendation.value?.track, RoadmapTrack.infrastructure);
      expect(find.text('Encontramos tu ruta'), findsOneWidget);
    });

    testWidgets('con el track ya confirmado sigue en la meta y el contador '
        'mantiene los 5 pasos', (tester) async {
      // Al confirmar, el paso 2 se sobreescribió con el track real; el rastro de
      // la rama guiada son las respuestas del cuestionario.
      repo.filas['experience_level'] = const OnboardingAnswer(
        stepKey: 'experience_level',
        value: 'student',
      );
      repo.filas['track'] =
          const OnboardingAnswer(stepKey: 'track', value: 'frontend');
      repo.filas['quiz_1'] =
          const OnboardingAnswer(stepKey: 'quiz_1', value: 'frontend');

      await restoreOnboarding();
      await _montar(tester);

      expect(usesGuidedQuiz.value, isTrue);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.goal);
      expect(find.text('PASO 4 DE 5'), findsOneWidget);
    });
  });

  group('Ningún camino llega al dashboard sin track', () {
    test('un perfil sin track no cuenta como onboarding completo', () {
      const sinTrack = UserProfile(id: 'u1', email: 'ana@example.com');

      expect(sinTrack.hasCompletedOnboarding, isFalse);
      expect(
        sinTrack
            .copyWith(onboardingCompletedAt: DateTime(2026, 7, 26))
            .hasCompletedOnboarding,
        isFalse,
      );
    });

    testWidgets('omitir todo lo omitible no permite terminar sin track',
        (tester) async {
      await _montar(tester);

      // Omite el nivel.
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      // En el paso del track no hay «Omitir» y «Continuar» está deshabilitado.
      expect(find.text('Omitir'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Continuar'),
            )
            .onPressed,
        isNull,
      );
      // Así que no hay forma de llegar al resumen sin track.
      expect(currentStep.value, OnboardingStepId.track);
    });

    testWidgets('forzar el resumen sin track no guarda y devuelve al paso 2',
        (tester) async {
      // Estado inalcanzable por la UI; la regla no puede depender de eso.
      currentStepIndex.value = 3;
      await _montar(tester);

      await tester.tap(find.text('Entrar al Dashboard'));
      await tester.pumpAndSettle();

      expect(currentProfile.value, isNull);
      expect(currentStep.value, OnboardingStepId.track);
    });
  });
}
