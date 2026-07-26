// Pruebas unitarias de la única lógica de negocio real del Módulo 1 (issue #8,
// AC3). No montan Flutter: la capa domain es Dart puro.

import 'package:flutter_test/flutter_test.dart';

import 'package:aspire_app/domain/entities/onboarding_answer.dart';
import 'package:aspire_app/domain/entities/roadmap_track.dart';
import 'package:aspire_app/domain/usecases/recommend_track_usecase.dart';

/// Respuestas del cuestionario guía, numeradas desde 1 como en el issue #12.
List<OnboardingAnswer> _quiz(List<String> valores) => [
      for (var i = 0; i < valores.length; i++)
        OnboardingAnswer(
          stepKey: OnboardingKeys.quizQuestion(i + 1),
          value: valores[i],
        ),
    ];

void main() {
  const usecase = RecommendTrackUseCase();

  group('cada track es recomendable', () {
    for (final track in RoadmapTrack.values) {
      test('mayoría de votos a ${track.slug} recomienda ${track.slug}', () {
        // 2 votos al track bajo prueba y 1 a otro distinto: mayoría clara.
        final otro = RoadmapTrack.values.firstWhere((t) => t != track);
        final result = usecase(_quiz([track.slug, track.slug, otro.slug]));

        expect(result.track, track);
        expect(result.wasTie, isFalse);
        expect(result.hasRecommendation, isTrue);
        expect(result.scores[track], 2);
        expect(result.scores[otro], 1);
      });
    }
  });

  test('sin respuestas no hay recomendación', () {
    final result = usecase(const <OnboardingAnswer>[]);

    expect(result.hasRecommendation, isFalse);
    expect(result.track, isNull);
    expect(result.wasTie, isFalse);
    // Los tres tracks presentes en cero: la UI puede pintar el desglose igual.
    expect(result.scores.length, RoadmapTrack.values.length);
    expect(result.scores.values.every((v) => v == 0), isTrue);
  });

  test('respuestas que no mapean a un track no cuentan como votos', () {
    // Nivel, meta y «aún no lo sé»: ninguna es un track.
    final result = usecase(const [
      OnboardingAnswer(
        stepKey: OnboardingKeys.experienceLevel,
        value: 'student',
      ),
      OnboardingAnswer(stepKey: OnboardingKeys.goal, value: 'first_job'),
      OnboardingAnswer(
        stepKey: OnboardingKeys.track,
        value: OnboardingKeys.unknownTrackValue,
      ),
    ]);

    expect(result.hasRecommendation, isFalse);
    expect(result.scores.values.every((v) => v == 0), isTrue);
  });

  test('empate entre los tres: gana frontend y queda marcado como empate', () {
    final result = usecase(_quiz([
      RoadmapTrack.backend.slug,
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.frontend.slug,
    ]));

    expect(result.wasTie, isTrue);
    expect(result.track, RoadmapTrack.frontend);
  });

  test('empate sin frontend: gana backend por orden de declaración', () {
    final result = usecase(_quiz([
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.backend.slug,
    ]));

    expect(result.wasTie, isTrue);
    expect(result.track, RoadmapTrack.backend);
  });

  test('el desempate es determinístico: el orden de llegada no lo altera', () {
    final a = usecase(_quiz([
      RoadmapTrack.infrastructure.slug,
      RoadmapTrack.backend.slug,
    ]));
    final b = usecase(_quiz([
      RoadmapTrack.backend.slug,
      RoadmapTrack.infrastructure.slug,
    ]));

    expect(a.track, b.track);
  });

  test('una sola respuesta alcanza y no es empate', () {
    final result = usecase(_quiz([RoadmapTrack.infrastructure.slug]));

    expect(result.track, RoadmapTrack.infrastructure);
    expect(result.wasTie, isFalse);
  });

  test('se puede pasar la lista completa del onboarding sin filtrar', () {
    // Es el caso de la reanudación (issue #14): loadAnswers() devuelve todo.
    final result = usecase([
      const OnboardingAnswer(
        stepKey: OnboardingKeys.experienceLevel,
        value: 'junior_developer',
      ),
      ..._quiz([RoadmapTrack.backend.slug, RoadmapTrack.backend.slug]),
      const OnboardingAnswer(
        stepKey: OnboardingKeys.goal,
        value: 'middle_level',
      ),
    ]);

    expect(result.track, RoadmapTrack.backend);
    expect(result.scores[RoadmapTrack.backend], 2);
  });
}
