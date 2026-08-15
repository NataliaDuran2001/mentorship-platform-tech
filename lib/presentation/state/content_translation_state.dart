// Presentation layer (State): AI-translated overlay for topics/theory
// challenges, shown when the learner's Settings language is not English.
//
// English is served straight from `roadmapTree`/`labChallenges` — the seeded
// source of truth — so only the Spanish overlay lives here, keyed by source
// id. Switching back to English needs no refetch, just falling back to the
// entities' own fields.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/entities/content_translation.dart';

/// Topic translations for the currently loaded roadmap tree, keyed by topic id.
final roadmapTopicTranslations = signal<Map<String, TopicTranslation>>(const {});

/// The language [roadmapTopicTranslations] was last fetched for.
///
/// `null` means never fetched. Compared against `appLanguage` so a language
/// switch triggers exactly one refetch instead of firing on every rebuild —
/// English is never recorded here, since it needs no fetch at all.
final roadmapTranslationsLoadedFor = signal<AppLanguage?>(null);

final roadmapTranslationsLoading = signal<bool>(false);

/// Theory challenge translations for the currently open lab, keyed by
/// challenge id. Replaced wholesale on every `loadLabs` call, so it never
/// mixes translations from a previously open topic.
final labTheoryTranslations = signal<Map<String, TheoryTranslation>>(const {});

final labTheoryTranslationsLoading = signal<bool>(false);

/// Exercise (multiple_choice/fill_blank/order_logic) translations for the
/// currently open lab, keyed by challenge id. Same replace-wholesale
/// reasoning as [labTheoryTranslations].
final labExerciseTranslations = signal<Map<String, ExerciseTranslation>>(const {});

final labExerciseTranslationsLoading = signal<bool>(false);

/// Leaves the translation overlays as if nothing had ever loaded. Called on
/// sign-out, same reasoning as `resetAiState`: this content is scoped to the
/// session's language, not to any one user, but resetting avoids a flash of
/// stale translations while the next session's roadmap/lab load.
void resetContentTranslationState() {
  roadmapTopicTranslations.value = const {};
  roadmapTranslationsLoadedFor.value = null;
  roadmapTranslationsLoading.value = false;

  labTheoryTranslations.value = const {};
  labTheoryTranslationsLoading.value = false;

  labExerciseTranslations.value = const {};
  labExerciseTranslationsLoading.value = false;
}
