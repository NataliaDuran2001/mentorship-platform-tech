// Data layer: Implementation of InterviewRepository.
//
// Both calls go through Supabase Edge Functions, which proxy to the Kimi3
// API (kimi-k3 by Moonshot AI), the same way AiRepositoryImpl does. Neither
// call is cached: generate-interview-questions must vary between calls by
// design, and analyze-interview-answer grades a unique piece of text every
// time.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/interview_answer_feedback.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/failures/ai_failure.dart';
import '../../domain/repositories/interview_repository.dart';

class InterviewRepositoryImpl implements InterviewRepository {
  const InterviewRepositoryImpl(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // generateQuestions
  // ---------------------------------------------------------------------------

  @override
  Future<List<InterviewQuestion>> generateQuestions({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-interview-questions',
        body: {
          'trackSlug': track.slug,
          'experienceLevelSlug': experienceLevel?.slug,
          'learningGoalSlug': learningGoal?.slug,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail:
              'generate-interview-questions returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final rawQuestions = data['questions'] as List<dynamic>?;
      if (rawQuestions == null || rawQuestions.isEmpty) {
        throw const AiFailure(
          AiFailureKind.invalidResponse,
          technicalDetail: 'questions field is missing or empty',
        );
      }

      return [
        for (var i = 0; i < rawQuestions.length; i++)
          _parseQuestion(rawQuestions[i] as Map<String, dynamic>, i),
      ];
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  InterviewQuestion _parseQuestion(Map<String, dynamic> data, int index) {
    final prompt = data['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      throw const AiFailure(
        AiFailureKind.invalidResponse,
        technicalDetail: 'question prompt is missing',
      );
    }
    final category = data['category'] as String?;
    return InterviewQuestion(
      id: 'q-$index',
      prompt: prompt,
      category: (category == null || category.isEmpty) ? 'technical' : category,
    );
  }

  // ---------------------------------------------------------------------------
  // analyzeAnswer
  // ---------------------------------------------------------------------------

  @override
  Future<InterviewAnswerFeedback> analyzeAnswer({
    required InterviewQuestion question,
    required String answerText,
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'analyze-interview-answer',
        body: {
          'trackSlug': track.slug,
          'experienceLevelSlug': experienceLevel?.slug,
          'questionPrompt': question.prompt,
          'answerText': answerText,
        },
      );

      if (response.status != 200) {
        throw AiFailure(
          AiFailureKind.serviceUnavailable,
          technicalDetail:
              'analyze-interview-answer returned ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return _parseFeedback(data);
    } on AiFailure {
      rethrow;
    } catch (e) {
      throw AiFailure(AiFailureKind.unknown, technicalDetail: e.toString());
    }
  }

  InterviewAnswerFeedback _parseFeedback(Map<String, dynamic> data) {
    final summary = data['summary'] as String?;
    final score = (data['score'] as num?)?.toInt();
    if (summary == null || summary.isEmpty || score == null) {
      throw const AiFailure(
        AiFailureKind.invalidResponse,
        technicalDetail: 'summary or score is missing',
      );
    }

    final strengths = (data['strengths'] as List<dynamic>? ?? [])
        .map((s) => s.toString())
        .toList();
    final improvements = (data['improvements'] as List<dynamic>? ?? [])
        .map((s) => s.toString())
        .toList();

    return InterviewAnswerFeedback(
      summary: summary,
      strengths: strengths,
      improvements: improvements,
      score: score.clamp(0, 100),
    );
  }
}
