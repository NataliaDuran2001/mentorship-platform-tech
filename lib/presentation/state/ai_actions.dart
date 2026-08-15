// Presentation layer (State): AI features actions (Daily Brief, Roadmap Coach, lab hints).
//
// Triggers the calls to the Edge Functions via AiRepository, handling the
// loading states and errors.

import '../../core/di/injection.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/entities/topic_node.dart';
import '../../domain/entities/roadmap_track.dart';
import '../utils/auth_error_messages.dart';
import '../utils/translate.dart';
import 'auth_state.dart';
import 'language_state.dart';
import 'roadmap_state.dart';
import 'roadmap_actions.dart';
import 'ai_state.dart';

/// Loads the personalized daily brief for the authenticated user.
///
/// Ensures the roadmap is loaded first to get correct progress numbers.
Future<void> loadDailyBrief() async {
  final profile = currentProfile.value;
  if (profile == null || dailyBriefLoading.value) return;

  dailyBriefLoading.value = true;
  dailyBriefError.value = null;

  try {
    // 1. Ensure roadmap/progress is loaded first to pass correct numbers to AI
    if (!roadmapLoaded.value) {
      await loadRoadmap();
    }

    // Without the progress numbers the summary would be about a path of 0 of 0
    // topics, which reads as "you have done nothing" instead of as a failure.
    if (roadmapError.value != null) {
      dailyBriefError.value = roadmapError.value;
      return;
    }

    final total = roadmapLeaves.value.length;
    final completed = roadmapCompletedCount.value;

    // 2. Fetch the brief from Kimi3 (or cache)
    final requestedLanguage = appLanguage.value;
    final briefText = await getIt<AiRepository>().generateDailyBrief(
      userId: profile.id,
      trackSlug: profile.track?.slug ?? 'frontend',
      experienceLevelSlug: profile.experienceLevel?.slug,
      learningGoalSlug: profile.learningGoal?.slug,
      completedTopics: completed,
      totalTopics: total,
      language: requestedLanguage,
    );

    dailyBrief.value = briefText;
    dailyBriefLanguage.value = requestedLanguage;
  } catch (e) {
    dailyBriefError.value = errorMessage(e);
  } finally {
    dailyBriefLoading.value = false;
  }
}

/// Loads the roadmap coach coaching message.
Future<void> loadRoadmapCoachMessage() async {
  final profile = currentProfile.value;
  if (profile == null || roadmapCoachLoading.value) return;

  roadmapCoachLoading.value = true;
  roadmapCoachError.value = null;

  try {
    if (!roadmapLoaded.value) {
      await loadRoadmap();
    }

    if (roadmapError.value != null) {
      roadmapCoachError.value = roadmapError.value;
      return;
    }

    final total = roadmapLeaves.value.length;
    final completed = roadmapCompletedCount.value;
    final progressFraction = total > 0 ? (completed / total) : 0.0;

    // Find the next available topic
    final nextTopic = roadmapLeaves.value.firstWhere(
      (node) => node.status == TopicStatus.available,
      orElse: () => const TopicNode(id: '', trackId: RoadmapTrack.frontend, title: '', sortOrder: 0),
    );
    final nextTopicTitle = nextTopic.title.isNotEmpty ? nextTopic.title : null;

    final requestedLanguage = appLanguage.value;
    final messageText = await getIt<AiRepository>().generateRoadmapCoachMessage(
      trackSlug: profile.track?.slug ?? 'frontend',
      learningGoalSlug: profile.learningGoal?.slug,
      progressFraction: progressFraction,
      nextTopicTitle: nextTopicTitle,
      language: requestedLanguage,
    );

    roadmapCoachMessage.value = messageText;
    roadmapCoachLanguage.value = requestedLanguage;
  } catch (e) {
    roadmapCoachError.value = errorMessage(e);
  } finally {
    roadmapCoachLoading.value = false;
  }
}

/// Loads the personalized welcome-back headline for the dashboard header.
Future<void> loadWelcomeMessage() async {
  final profile = currentProfile.value;
  if (profile == null || welcomeMessageLoading.value) return;

  welcomeMessageLoading.value = true;
  welcomeMessageError.value = null;

  try {
    if (!roadmapLoaded.value) {
      await loadRoadmap();
    }

    if (roadmapError.value != null) {
      welcomeMessageError.value = roadmapError.value;
      return;
    }

    final total = roadmapLeaves.value.length;
    final completed = roadmapCompletedCount.value;
    final progressFraction = total > 0 ? (completed / total) : 0.0;

    final requestedLanguage = appLanguage.value;
    final messageText = await getIt<AiRepository>().generateWelcomeMessage(
      displayName:
          profile.displayName ?? tr('Learner', 'Estudiante'),
      trackSlug: profile.track?.slug,
      learningGoalSlug: profile.learningGoal?.slug,
      progressFraction: progressFraction,
      language: requestedLanguage,
    );

    welcomeMessage.value = messageText;
    welcomeMessageLanguage.value = requestedLanguage;
  } catch (e) {
    welcomeMessageError.value = errorMessage(e);
  } finally {
    welcomeMessageLoading.value = false;
  }
}

/// Requests a new hint for a lab challenge.
///
/// Increments the local hints count for that topic and caches the response.
Future<void> requestLabHint(String topicId, String challengeQuestion, String challengeType) async {
  labHintLoading.value = true;
  labHintError.value = null;

  try {
    final currentHintsList = labHints.value[topicId] ?? const <String>[];
    final attemptCount = currentHintsList.length + 1;

    final hintText = await getIt<AiRepository>().generateLabHint(
      challengeQuestion: challengeQuestion,
      challengeType: challengeType,
      attemptCount: attemptCount,
      userContext: currentProfile.value?.experienceLevel?.slug,
      language: appLanguage.value,
    );

    final updatedList = List<String>.from(currentHintsList)..add(hintText);
    labHints.value = {
      ...labHints.value,
      topicId: updatedList,
    };
  } catch (e) {
    labHintError.value = errorMessage(e);
  } finally {
    labHintLoading.value = false;
  }
}

/// Clears hints for a specific topic (e.g. when completed/moved next)
void clearLabHintsForTopic(String topicId) {
  final updatedHints = Map<String, List<String>>.from(labHints.value)..remove(topicId);
  labHints.value = updatedHints;
}
