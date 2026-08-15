// Presentation layer (State): Settings language action.
//
// Mirrors changePassword's shape in auth_actions.dart: a direct repository
// call from the action, no usecase needed for a single-field setting.

import '../../core/di/injection.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../utils/auth_error_messages.dart';
import 'auth_state.dart';
import 'language_state.dart';

/// Updates the Settings language and refreshes [currentProfile] so every
/// screen reading [appLanguage] picks it up immediately.
Future<void> updateLanguage(AppLanguage language) async {
  if (appLanguage.value == language) return;

  languageUpdateLoading.value = true;
  languageUpdateError.value = null;

  try {
    final profile = await getIt<OnboardingRepository>().updateLanguage(
      language: language,
    );
    currentProfile.value = profile;
  } catch (e) {
    languageUpdateError.value = errorMessage(e);
  } finally {
    languageUpdateLoading.value = false;
  }
}
