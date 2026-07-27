// Pruebas del flujo de onboarding directo (issue #11).
//
// Lo que se prueba es el comportamiento del recorrido, que es donde está el
// riesgo: qué pasos hay, cuál se puede omitir, qué conserva al volver, qué
// muestra el contador y qué se persiste al terminar.
//
// El estado del onboarding y el de auth son globales al proceso, así que cada
// prueba los reinicia en setUp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/core/di/injection.dart';
import 'package:aspire_app/domain/entities/experience_level.dart';
import 'package:aspire_app/domain/entities/learning_goal.dart';
import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/entities/user_profile.dart';
import 'package:aspire_app/domain/failures/auth_failure.dart';
import 'package:aspire_app/domain/repositories/onboarding_repository.dart';
import 'package:aspire_app/domain/usecases/submit_onboarding_usecase.dart';
import 'package:aspire_app/presentation/state/auth_state.dart';
import 'package:aspire_app/presentation/state/onboarding_actions.dart';
import 'package:aspire_app/presentation/state/onboarding_state.dart';
import 'package:aspire_app/presentation/utils/onboarding_labels.dart';
import 'package:aspire_app/presentation/widgets/pages/onboarding_page.dart';

/// Registra qué se guardó, para poder afirmar sobre las cuatro columnas.
class SpyOnboardingRepository implements OnboardingRepository {
  RoadmapTrack? trackGuardado;
  ExperienceLevel? nivelGuardado;
  LearningGoal? metaGuardada;
  int llamadas = 0;
  AuthFailure? fallo;

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    llamadas++;
    if (fallo != null) throw fallo!;

    trackGuardado = track;
    nivelGuardado = experienceLevel;
    metaGuardada = learningGoal;

    return UserProfile(
      id: 'u1',
      email: 'ana@example.com',
      experienceLevel: experienceLevel,
      track: track,
      learningGoal: learningGoal,
      onboardingCompletedAt: DateTime(2026, 7, 26),
    );
  }

  @override
  Future<UserProfile?> loadProfile() async => null;

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async =>
      const <OnboardingAnswer>[];

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {}
}

/// Monta la página sola, con el tema por defecto y una ventana amplia.
Future<void> _montar(WidgetTester tester, {Size? tamano}) async {
  tester.view.physicalSize = tamano ?? const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
}

/// Espera el auto-avance de 400 ms.
Future<void> _esperarAutoAvance(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 600));

void main() {
  late SpyOnboardingRepository repo;

  setUp(() {
    repo = SpyOnboardingRepository();
    overrideDependency<OnboardingRepository>(repo);
    overrideDependency(SubmitOnboardingUseCase(repo));

    resetOnboarding();
    cancelOnboardingTimers();
    currentProfile.value = null;
  });

  tearDown(cancelOnboardingTimers);

  group('Recorrido y contador', () {
    testWidgets('arranca en el paso 1 de 4', (tester) async {
      await _montar(tester);

      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(find.text('¡Hola! ¿Cómo te identificás hoy?'), findsOneWidget);
      // Los 3 niveles del prototipo, con sus textos exactos.
      expect(find.text('Estudiante / Autodidacta'), findsOneWidget);
      expect(find.text('Junior Developer'), findsOneWidget);
      expect(find.text('Cambiando de Carrera'), findsOneWidget);
    });

    testWidgets('elegir una opción avanza sola tras 400 ms', (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Junior Developer'));
      await tester.pump();

      // Antes del temporizador sigue en el paso 1, con la opción marcada: es el
      // feedback visual que la pausa existe para mostrar.
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);

      await _esperarAutoAvance(tester);

      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      expect(find.text('¿Cuál es tu especialidad?'), findsOneWidget);
    });

    testWidgets('la barra de progreso refleja el total real de pasos',
        (tester) async {
      await _montar(tester);
      await tester.pumpAndSettle();

      // Paso 1 de 4 → 25%, igual que el prototipo.
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.25, 0.001),
      );

      // Al entrar a la rama guiada el total pasa a 5 y la misma posición vale
      // otra fracción.
      usesGuidedQuiz.value = true;
      currentStepIndex.value = 0;
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 5'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        closeTo(0.2, 0.001),
      );
    });
  });

  group('Paso 2: especialidad', () {
    testWidgets('ofrece los 3 tracks decididos más «Aún no lo sé»',
        (tester) async {
      currentStepIndex.value = 1;
      await _montar(tester);

      expect(find.text('Front-end'), findsOneWidget);
      expect(find.text('Back-end'), findsOneWidget);
      expect(find.text('Infraestructura'), findsOneWidget);
      expect(find.text(opcionNoLoSe.label), findsOneWidget);

      // Los tracks que el mockup ofrece pero el MVP no tiene.
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('UI / UX Design'), findsNothing);
    });

    testWidgets('«Omitir» no está disponible acá, pero sí en los pasos 1 y 3',
        (tester) async {
      // Paso 1: omitible.
      await _montar(tester);
      expect(find.text('Omitir'), findsOneWidget);

      // Paso 2: prohibido. Sin track no hay roadmap (CA 1.3).
      currentStepIndex.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('Omitir'), findsNothing);

      // Paso 3: omitible otra vez.
      currentStepIndex.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('¿Cuál es tu meta principal?'), findsOneWidget);
      expect(find.text('Omitir'), findsOneWidget);
    });

    testWidgets('«Continuar» está deshabilitado hasta elegir un track',
        (tester) async {
      currentStepIndex.value = 1;
      await _montar(tester);

      final boton = find.widgetWithText(ElevatedButton, 'Continuar');
      expect(tester.widget<ElevatedButton>(boton).onPressed, isNull);

      await tester.tap(find.text('Back-end'));
      await tester.pump();

      expect(tester.widget<ElevatedButton>(boton).onPressed, isNotNull);

      // Deja correr el auto-avance: un temporizador pendiente al terminar la
      // prueba hace fallar al framework.
      await _esperarAutoAvance(tester);
    });

    testWidgets('«Aún no lo sé» activa la rama guiada y el contador pasa a 5',
        (tester) async {
      currentStepIndex.value = 1;
      await _montar(tester);

      await tester.tap(find.text(opcionNoLoSe.label));
      await _esperarAutoAvance(tester);

      expect(usesGuidedQuiz.value, isTrue);
      expect(selectedTrack.value, isNull);
      expect(totalSteps.value, 5);
      expect(currentStep.value, OnboardingStepId.quiz);
      expect(find.text('PASO 3 DE 5'), findsOneWidget);
    });
  });

  group('Regresar', () {
    testWidgets('preserva lo ya seleccionado', (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Junior Developer'));
      await _esperarAutoAvance(tester);
      await tester.tap(find.text('Front-end'));
      await _esperarAutoAvance(tester);

      expect(find.text('¿Cuál es tu meta principal?'), findsOneWidget);

      await tester.tap(find.text('Regresar'));
      await tester.pumpAndSettle();

      // Vuelve al paso 2 con Front-end todavía elegido.
      expect(find.text('¿Cuál es tu especialidad?'), findsOneWidget);
      expect(selectedTrack.value, RoadmapTrack.frontend);

      await tester.tap(find.text('Regresar'));
      await tester.pumpAndSettle();

      // Y al paso 1 con el nivel todavía elegido.
      expect(selectedLevel.value, ExperienceLevel.juniorDeveloper);
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
    });

    testWidgets('volver desde el cuestionario guía reabre el paso del track',
        (tester) async {
      currentStepIndex.value = 1;
      await _montar(tester);

      await tester.tap(find.text(opcionNoLoSe.label));
      await _esperarAutoAvance(tester);
      expect(currentStep.value, OnboardingStepId.quiz);

      await tester.tap(find.text('Regresar'));
      await tester.pumpAndSettle();

      // La rama se desactiva y el total vuelve a 4: la usuaria está
      // reconsiderando su especialidad.
      expect(usesGuidedQuiz.value, isFalse);
      expect(totalSteps.value, 4);
      expect(currentStep.value, OnboardingStepId.track);
    });

    testWidgets('en el primer paso no se ofrece «Regresar»', (tester) async {
      await _montar(tester);

      final boton = find.widgetWithText(TextButton, 'Regresar');
      expect(tester.widget<TextButton>(boton).onPressed, isNull);
    });
  });

  group('Resumen y persistencia', () {
    testWidgets('completar el flujo persiste nivel, track y meta',
        (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Junior Developer'));
      await _esperarAutoAvance(tester);
      await tester.tap(find.text('Front-end'));
      await _esperarAutoAvance(tester);
      await tester.tap(find.text('Conseguir mi primer empleo profesional'));
      await _esperarAutoAvance(tester);

      // Paso 4: el resumen, con Nivel y Foco como en el prototipo.
      expect(find.text('PASO 4 DE 4'), findsOneWidget);
      expect(find.text('¡Todo listo!'), findsOneWidget);
      expect(find.text('Junior Developer'), findsOneWidget);
      expect(find.text('Front-end'), findsOneWidget);
      expect(find.text('Entrar al Dashboard'), findsOneWidget);

      await tester.tap(find.text('Entrar al Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.llamadas, 1);
      expect(repo.nivelGuardado, ExperienceLevel.juniorDeveloper);
      expect(repo.trackGuardado, RoadmapTrack.frontend);
      expect(repo.metaGuardada, LearningGoal.firstJob);

      // Deja el perfil completo en el estado: es lo que hace que el route guard
      // del #9 deje pasar al dashboard.
      expect(currentProfile.value?.hasCompletedOnboarding, isTrue);
    });

    testWidgets('omitir un paso guarda null, no un valor inventado',
        (tester) async {
      await _montar(tester);

      // Omite el nivel.
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Infraestructura'));
      await _esperarAutoAvance(tester);

      // Omite la meta.
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(find.text('¡Todo listo!'), findsOneWidget);
      // Lo omitido se muestra, no se esconde.
      expect(find.text('Sin definir'), findsNWidgets(2));

      await tester.tap(find.text('Entrar al Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.trackGuardado, RoadmapTrack.infrastructure);
      expect(repo.nivelGuardado, isNull);
      expect(repo.metaGuardada, isNull);
    });

    testWidgets('un fallo al guardar se muestra traducido y no navega',
        (tester) async {
      repo.fallo = const AuthFailure(
        AuthFailureKind.network,
        technicalDetail: 'SocketException',
      );
      selectedTrack.value = RoadmapTrack.backend;
      currentStepIndex.value = 3;

      await _montar(tester);
      await tester.tap(find.text('Entrar al Dashboard'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No pudimos conectarnos'), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
      expect(currentProfile.value, isNull);
    });

    testWidgets('sin track no se guarda nada y devuelve al paso 2',
        (tester) async {
      // Estado imposible por la UI, pero la regla no puede depender de eso.
      currentStepIndex.value = 3;
      await _montar(tester);

      await tester.tap(find.text('Entrar al Dashboard'));
      await tester.pumpAndSettle();

      expect(repo.llamadas, 0);
      expect(currentStep.value, OnboardingStepId.track);
      expect(
        find.textContaining('Necesitamos saber tu especialidad'),
        findsOneWidget,
      );
    });
  });

  group('Responsivo', () {
    testWidgets('en móvil no se muestra la columna decorativa',
        (tester) async {
      await _montar(tester, tamano: const Size(420, 1600));
      await tester.pumpAndSettle();

      expect(find.text('Tu futuro empieza acá'), findsNothing);
      expect(find.text('¡Hola! ¿Cómo te identificás hoy?'), findsOneWidget);
    });

    testWidgets('en escritorio sí', (tester) async {
      await _montar(tester, tamano: const Size(1200, 2400));
      await tester.pumpAndSettle();

      expect(find.text('Tu futuro empieza acá'), findsOneWidget);
    });
  });
}
