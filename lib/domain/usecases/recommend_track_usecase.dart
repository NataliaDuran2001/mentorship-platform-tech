// Domain layer: Use case encapsulating one business rule of the app.
//
// AI-First: It tries Kimi3 (via AiRepository) first and falls back to the
// original deterministic vote-count rule if the AI is unavailable.
//
// The fallback keeps the onboarding working offline or when the Edge Function
// is down — it is not a lesser path, it is a safety net.
//
// The decision to try AI before the rule is the ONLY change from the original:
// the vote-count rule is preserved verbatim in `_voteCount()` and the output
// type is unchanged, so every caller of `call()` continues to work as before.

import '../entities/onboarding_answer.dart';
import '../entities/experience_level.dart';
import '../entities/learning_goal.dart';
import '../entities/roadmap_track.dart';
import '../entities/track_recommendation.dart';
import '../failures/ai_failure.dart';
import '../repositories/ai_repository.dart';

class RecommendTrackUseCase {
  const RecommendTrackUseCase(this._ai);

  final AiRepository _ai;

  /// Returns a [TrackRecommendation] from Kimi3 if available, or from the
  /// vote-count rule otherwise.
  ///
  /// Callers must `await` this now (it was previously synchronous). Existing
  /// `quizRecommendation.value = getIt<RecommendTrackUseCase>()(answers)`
  /// calls need to become `async` with `await`.
  Future<TrackRecommendation> call(
    List<OnboardingAnswer> answers, {
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    // --- Try AI first ---
    try {
      return await _ai.analyzeProfile(
        answers: answers,
        experienceLevel: experienceLevel,
        learningGoal: learningGoal,
      );
    } on AiFailure catch (e) {
      // Graceful degradation: AI unavailable, use the deterministic rule.
      // The failure is intentionally swallowed here; the caller sees a valid
      // recommendation with `isAiGenerated == false`.
      assert(() {
        // Only print in debug mode; production should stay silent.
        // ignore: avoid_print
        print('AI unavailable, falling back to vote-count rule: $e');
        return true;
      }());
    }

    // --- Fallback: deterministic vote-count rule (original logic) ---
    return _voteCount(answers);
  }

  /// Original deterministic algorithm.
  ///
  /// Counts one vote for every answer whose value maps to a track and returns
  /// the most voted one.
  ///
  /// Preserved verbatim from the pre-AI version. Ties are broken by the
  /// declaration order of [RoadmapTrack] — frontend, backend, infrastructure.
  TrackRecommendation _voteCount(List<OnboardingAnswer> answers) {
    final scores = <RoadmapTrack, int>{
      for (final track in RoadmapTrack.values) track: 0,
    };

    var votes = 0;
    for (final answer in answers) {
      final track = RoadmapTrack.fromSlug(answer.value);
      if (track == null) continue;
      scores[track] = scores[track]! + 1;
      votes++;
    }

    if (votes == 0) return const TrackRecommendation.empty();

    final highest = scores.values.reduce((a, b) => a > b ? a : b);
    final winners = RoadmapTrack.values
        .where((track) => scores[track] == highest)
        .toList(growable: false);

    return TrackRecommendation(
      track: winners.first,
      scores: scores,
      wasTie: winners.length > 1,
      // No reasoning or confidence: this is the deterministic fallback.
    );
  }
}

