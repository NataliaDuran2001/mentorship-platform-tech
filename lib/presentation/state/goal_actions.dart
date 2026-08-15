// Presentation layer (State): Learning goal editing action.
//
// Mirrors updateLanguage in language_actions.dart: a direct repository call,
// no usecase needed for a single-field update outside the onboarding flow.

import '../../core/di/injection.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'goal_state.dart';

/// Updates the learning goal from the Profile page and refreshes
/// [currentProfile] so every screen reading it picks up the change
/// immediately.
Future<void> updateLearningGoal(LearningGoal goal) async {
  if (currentProfile.value?.learningGoal == goal) return;

  goalUpdateLoading.value = true;
  goalUpdateError.value = null;

  try {
    final profile = await getIt<OnboardingRepository>().updateLearningGoal(
      goal: goal,
    );
    currentProfile.value = profile;
  } catch (e) {
    goalUpdateError.value = errorMessage(e);
  } finally {
    goalUpdateLoading.value = false;
  }
}
