// Presentation layer (State): Keeps the Spanish overlay of topics/theory
// challenges in sync with the learner's Settings language.
//
// English needs no network call: `roadmapTree`/`labChallenges` already hold
// it, straight from the seeded source of truth. This only fetches and caches
// the Spanish translation.

import '../../core/di/injection.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/repositories/ai_repository.dart';
import 'content_translation_state.dart';
import 'language_state.dart';
import 'roadmap_state.dart';

/// Ensures the roadmap tree's topic titles/descriptions are translated for
/// the current Settings language.
///
/// Called from `RoadmapPage`'s build, mirroring how that page asks for its
/// own AI coach message: this page's content is its own to translate. Guarded
/// by [roadmapTranslationsLoadedFor] so a language switch triggers exactly
/// one refetch instead of firing on every rebuild.
Future<void> ensureRoadmapTranslations() async {
  final language = appLanguage.value;
  if (language == AppLanguage.en) {
    // English is the seeded source — nothing to fetch. But a Spanish
    // overlay fetched earlier in the session is still sitting in memory, and
    // `_titleFor`/`_descriptionFor` in roadmap_tree.dart would keep showing
    // it forever otherwise: they only fall back to the node's own English
    // fields when the map has no entry for that id.
    if (roadmapTopicTranslations.value.isNotEmpty ||
        roadmapTranslationsLoadedFor.value != null) {
      roadmapTopicTranslations.value = const {};
      roadmapTranslationsLoadedFor.value = AppLanguage.en;
    }
    return;
  }
  if (roadmapTranslationsLoadedFor.value == language) return;
  if (roadmapTranslationsLoading.value) return;

  final topicIds = [
    for (final root in roadmapTree.value) ...root.flattened.map((n) => n.id),
  ];
  if (topicIds.isEmpty) return;

  roadmapTranslationsLoading.value = true;
  try {
    final translations = await getIt<AiRepository>().translateTopics(
      topicIds: topicIds,
      language: language,
    );
    roadmapTopicTranslations.value = translations;
    roadmapTranslationsLoadedFor.value = language;
  } catch (_) {
    // Elegant degradation: the tree keeps showing the English titles it
    // already has, same as a failed daily brief falls back to static copy.
  } finally {
    roadmapTranslationsLoading.value = false;
  }
}

/// Translates the theory challenges of the lab that just loaded, for the
/// current Settings language.
///
/// Called from `loadLabs` right after the English challenges arrive, so it
/// always runs fresh for whichever topic is open — same as the challenges
/// themselves, which `loadLabs` never caches across topics.
Future<void> ensureLabTheoryTranslations(List<String> theoryChallengeIds) async {
  final language = appLanguage.value;
  if (language == AppLanguage.en || theoryChallengeIds.isEmpty) return;

  labTheoryTranslationsLoading.value = true;
  try {
    labTheoryTranslations.value =
        await getIt<AiRepository>().translateTheoryChallenges(
      challengeIds: theoryChallengeIds,
      language: language,
    );
  } catch (_) {
    // Elegant degradation: the lab keeps showing the English blocks it
    // already has.
  } finally {
    labTheoryTranslationsLoading.value = false;
  }
}

/// Translates the exercises (multiple_choice/fill_blank/order_logic) of the
/// lab that just loaded, for the current Settings language.
///
/// Same reasoning as [ensureLabTheoryTranslations]: called from `loadLabs`
/// right after the English challenges arrive, so it always runs fresh.
Future<void> ensureLabExerciseTranslations(List<String> exerciseChallengeIds) async {
  final language = appLanguage.value;
  if (language == AppLanguage.en || exerciseChallengeIds.isEmpty) return;

  labExerciseTranslationsLoading.value = true;
  try {
    labExerciseTranslations.value =
        await getIt<AiRepository>().translateExerciseChallenges(
      challengeIds: exerciseChallengeIds,
      language: language,
    );
  } catch (_) {
    // Elegant degradation: the lab keeps showing the English wording it
    // already has.
  } finally {
    labExerciseTranslationsLoading.value = false;
  }
}
