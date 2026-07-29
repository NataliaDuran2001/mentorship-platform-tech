// Presentation layer (State): Roadmap actions.

import '../../core/di/injection.dart';
import '../../domain/usecases/get_roadmap_tree_usecase.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'roadmap_state.dart';
import 'ai_actions.dart';

/// Loads the topic tree of the user's track.
///
/// The track comes from the profile: if there is none, there is nothing to load
/// and the route guards already made sure that does not happen with the
/// onboarding completed.
Future<void> loadRoadmap() async {
  final track = currentProfile.value?.track;
  if (track == null) {
    roadmapTree.value = const [];
    roadmapLoaded.value = true;
    return;
  }

  roadmapLoading.value = true;
  roadmapError.value = null;

  try {
    // The use case builds the hierarchy and derives the sequential state; here
    // nothing is sorted nor is it decided what is unlocked.
    roadmapTree.value = await getIt<GetRoadmapTreeUseCase>()(track);
    roadmapLoaded.value = true;

    // Trigger AI features that depend on the roadmap progress
    loadRoadmapCoachMessage();
    loadDailyBrief();
  } catch (e) {
    roadmapError.value = errorMessage(e);
  } finally {
    roadmapLoading.value = false;
  }
}

/// Retries the load after an error.
Future<void> retryRoadmap() {
  roadmapError.value = null;
  return loadRoadmap();
}
