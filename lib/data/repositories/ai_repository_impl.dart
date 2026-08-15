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

import '../../domain/entities/app_language.dart';
import '../../domain/entities/content_translation.dart';
import '../../domain/entities/experience_level.dart';
import '../../domain/entities/lab_challenge.dart';
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
    required AppLanguage language,
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
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'analyze-profile returned ${response.status}',
        );
      }

      final data = (response.data as Map).cast<String, dynamic>();
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
    required AppLanguage language,
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
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'daily-brief returned ${response.status}',
        );
      }

      final data = (response.data as Map).cast<String, dynamic>();
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
    required AppLanguage language,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'lab-hint',
        body: {
          'challengeQuestion': challengeQuestion,
          'challengeType': challengeType,
          'attemptCount': attemptCount,
          'userContext': userContext,
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'lab-hint returned ${response.status}',
        );
      }

      final data = (response.data as Map).cast<String, dynamic>();
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
    required AppLanguage language,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'roadmap-coach',
        body: {
          'trackSlug': trackSlug,
          'learningGoalSlug': learningGoalSlug,
          'progressPercent': (progressFraction * 100).round(),
          'nextTopicTitle': nextTopicTitle,
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'roadmap-coach returned ${response.status}',
        );
      }

      final data = (response.data as Map).cast<String, dynamic>();
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

  // ---------------------------------------------------------------------------
  // generateWelcomeMessage
  // ---------------------------------------------------------------------------

  @override
  Future<String> generateWelcomeMessage({
    required String displayName,
    required String? trackSlug,
    required String? learningGoalSlug,
    required double progressFraction,
    required AppLanguage language,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'welcome-message',
        body: {
          'displayName': displayName,
          'trackSlug': trackSlug,
          'learningGoalSlug': learningGoalSlug,
          'progressPercent': (progressFraction * 100).round(),
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'welcome-message returned ${response.status}',
        );
      }

      final data = (response.data as Map).cast<String, dynamic>();
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

  // ---------------------------------------------------------------------------
  // translateTopics / translateTheoryChallenges
  // ---------------------------------------------------------------------------

  /// Shared call to the `translate-content` Edge Function.
  ///
  /// Returns raw `sourceId -> content` JSON. Items that failed to translate
  /// server-side are simply absent — not an error, since the caller degrades
  /// to the English content it already holds.
  Future<Map<String, Map<String, dynamic>>> _translateContent({
    required String sourceTable,
    required List<String> sourceIds,
    required AppLanguage language,
  }) async {
    if (sourceIds.isEmpty) return const {};

    try {
      final response = await _client.functions.invoke(
        'translate-content',
        body: {
          'items': [
            for (final id in sourceIds) {'sourceTable': sourceTable, 'sourceId': id},
          ],
          'language': language.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail: 'translate-content returned ${response.status}',
        );
      }

      final data = (response.data as Map).cast<String, dynamic>();
      final rawTranslations = (data['translations'] as List?) ?? const [];

      return {
        for (final entry in rawTranslations)
          (entry as Map)['sourceId'] as String:
              (entry['content'] as Map).cast<String, dynamic>(),
      };
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  @override
  Future<Map<String, TopicTranslation>> translateTopics({
    required List<String> topicIds,
    required AppLanguage language,
  }) async {
    final raw = await _translateContent(
      sourceTable: 'topics',
      sourceIds: topicIds,
      language: language,
    );

    return {
      for (final entry in raw.entries)
        entry.key: TopicTranslation(
          title: entry.value['title'] as String,
          description: entry.value['description'] as String?,
        ),
    };
  }

  @override
  Future<Map<String, TheoryTranslation>> translateTheoryChallenges({
    required List<String> challengeIds,
    required AppLanguage language,
  }) async {
    final raw = await _translateContent(
      sourceTable: 'lab_challenges',
      sourceIds: challengeIds,
      language: language,
    );

    return {
      for (final entry in raw.entries)
        entry.key: TheoryTranslation(
          question: entry.value['question'] as String,
          blocks: _theoryBlocks(entry.value['blocks'] as List?),
          keyTakeaway: entry.value['keyTakeaway'] as String?,
        ),
    };
  }

  @override
  Future<Map<String, ExerciseTranslation>> translateExerciseChallenges({
    required List<String> challengeIds,
    required AppLanguage language,
  }) async {
    final raw = await _translateContent(
      sourceTable: 'lab_challenges',
      sourceIds: challengeIds,
      language: language,
    );

    return {
      for (final entry in raw.entries)
        entry.key: ExerciseTranslation(
          question: entry.value['question'] as String,
          description: entry.value['description'] as String?,
          items: (entry.value['items'] as Map?)?.cast<String, String>(),
        ),
    };
  }

  /// Mirrors `LabRepositoryImpl._theoryBlocks`: an unrecognized block `type`
  /// is dropped instead of throwing, since this content is model-generated
  /// and a missing paragraph is better than an unreadable topic.
  static List<TheoryBlock> _theoryBlocks(List? raw) {
    if (raw == null) return const <TheoryBlock>[];

    final blocks = <TheoryBlock>[];
    for (final entry in raw) {
      final map = (entry as Map).cast<String, dynamic>();
      final type = switch (map['type'] as String?) {
        'paragraph' => TheoryBlockType.paragraph,
        'code' => TheoryBlockType.code,
        'list' => TheoryBlockType.list,
        _ => null,
      };
      if (type == null) continue;

      blocks.add(
        TheoryBlock(
          type: type,
          text: map['text'] as String?,
          items: (map['items'] as List?)?.cast<String>() ?? const <String>[],
          language: map['language'] as String?,
        ),
      );
    }
    return List<TheoryBlock>.unmodifiable(blocks);
  }
}
