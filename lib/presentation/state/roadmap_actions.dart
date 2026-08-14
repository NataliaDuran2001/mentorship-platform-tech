// Presentation layer (State): Roadmap actions.

import '../../core/di/injection.dart';
import '../../domain/usecases/get_roadmap_tree_usecase.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'roadmap_state.dart';

/// The load currently in flight, if any.
///
/// More than one caller asks for the roadmap on the same frame —the page paints
/// it and the AI actions need its progress numbers— and they must not fire two
/// requests nor read a half-loaded tree. Everyone awaits the same future.
Future<void>? _inFlight;

/// Loads the topic tree of the user's track.
///
/// The track comes from the profile: if there is none, there is nothing to load
/// and the route guards already made sure that does not happen with the
/// onboarding completed.
///
/// It does not trigger the AI features: each page asks for the one it shows.
/// Chaining them here meant that a failing roadmap left the dashboard's card
/// silently empty, with no request ever made and no error to report.
Future<void> loadRoadmap() {
  return _inFlight ??= _loadRoadmap().whenComplete(() => _inFlight = null);
}

Future<void> _loadRoadmap() async {
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
