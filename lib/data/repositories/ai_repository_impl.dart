// Data layer: Implementation of AiRepository.
//
// All AI calls go through Supabase Edge Functions, which proxy to the
// Kimi3 API (kimi-k3 by Moonshot AI). The API key never leaves the server.
//
// Graceful degradation strategy:
// - analyzeProfile: on AiFailure, the caller (RecommendTrackUseCase) falls
//   back to the deterministic vote-count rule.
// - generateDailyBrief / generateRoadmapCoachMessage: on failure the
//   presentation layer shows a generic static message.
// - generateLabHint: on failure the hint button is hidden or shows an error.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/onboarding_answer.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/track_recommendation.dart';
import '../../domain/failures/ai_failure.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // analyzeProfile
  // ---------------------------------------------------------------------------

  @override
  Future<TrackRecommendation> analyzeProfile({
    required List<OnboardingAnswer> answers,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'analyze-profile',
        body: {
          'answers': answers
              .map((a) => {'stepKey': a.stepKey, 'value': a.value})
              .toList(),
          'experienceLevel': experienceLevel?.slug,
          'learningGoal': learningGoal?.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'analyze-profile returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return _parseTrackRecommendation(data);
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  TrackRecommendation _parseTrackRecommendation(Map<String, dynamic> data) {
    final trackSlug = data['recommendedTrack'] as String?;
    final track = RoadmapTrack.fromSlug(trackSlug);

    if (track == null) {
      throw const AiFailure(
        AiFailureKind.invalidResponse,
        technicalDetail: 'recommendedTrack is missing or invalid',
      );
    }

    final reasoning = data['reasoning'] as String?;
    final confidence = (data['confidence'] as num?)?.toDouble();

    // Build an alternatives list from the AI response if present.
    final rawAlternatives = data['alternatives'] as List<dynamic>? ?? [];
    final alternatives = rawAlternatives
        .map((alt) {
          final altMap = alt as Map<String, dynamic>;
          final altTrack = RoadmapTrack.fromSlug(altMap['track'] as String?);
          final altReason = altMap['reason'] as String?;
          if (altTrack == null || altReason == null) return null;
          return TrackAlternative(track: altTrack, reason: altReason);
        })
        .whereType<TrackAlternative>()
        .toList();

    // Build the scores map: recommended track gets 100, others get 0.
    // This keeps the UI compatible with the existing vote-count display.
    final scores = <RoadmapTrack, int>{
      for (final t in RoadmapTrack.values) t: t == track ? 100 : 0,
    };

    return TrackRecommendation(
      track: track,
      scores: scores,
      wasTie: (confidence != null && confidence < 0.85) || alternatives.isNotEmpty,
      reasoning: reasoning,
      confidence: confidence,
      alternatives: alternatives,
    );
  }

  // ---------------------------------------------------------------------------
  // generateDailyBrief
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateDailyBrief({
    required String userId,
    required String trackSlug,
    required String? experienceLevelSlug,
    required String? learningGoalSlug,
    required int completedTopics,
    required int totalTopics,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'daily-brief',
        body: {
          'trackSlug': trackSlug,
          'experienceLevelSlug': experienceLevelSlug,
          'learningGoalSlug': learningGoalSlug,
          'completedTopics': completedTopics,
          'totalTopics': totalTopics,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'daily-brief returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final text = data['brief'] as String?;
      if (text == null || text.isEmpty) {
        throw const AiFailure(
          AiFailureKind.invalidResponse,
          technicalDetail: 'brief field is missing',
        );
      }
      return text;
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // generateLabHint
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateLabHint({
    required String challengeQuestion,
    required String challengeType,
    required int attemptCount,
    required String? userContext,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'lab-hint',
        body: {
          'challengeQuestion': challengeQuestion,
          'challengeType': challengeType,
          'attemptCount': attemptCount,
          'userContext': userContext,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'lab-hint returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final hint = data['hint'] as String?;
      if (hint == null || hint.isEmpty) {
        throw const AiFailure(
          AiFailureKind.invalidResponse,
          technicalDetail: 'hint field is missing',
        );
      }
      return hint;
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // generateRoadmapCoachMessage
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateRoadmapCoachMessage({
    required String trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required String? nextTopicTitle,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'roadmap-coach',
        body: {
          'trackSlug': trackSlug,
          'learningGoalSlug': learningGoalSlug,
          'progressPercent': (progressFraction * 100).round(),
          'nextTopicTitle': nextTopicTitle,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'roadmap-coach returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as String?;
      if (message == null || message.isEmpty) {
        throw const AiFailure(
          AiFailureKind.invalidResponse,
          technicalDetail: 'message field is missing',
        );
      }
      return message;
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }
}
