// Presentation layer (State): The app's current UI/AI language.
//
// Derived from the authenticated profile, not a standalone signal set
// directly by the UI: the language is a Settings field like any other
// profile field, and this keeps every screen that reads it in sync the
// moment the profile reloads (e.g. after `updateLanguage`).
//
// Before login (no profile yet) it defaults to English, the app's original
// baseline — Settings only exists inside the authenticated Profile page, so
// pre-auth screens never had a language to read anyway.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/app_language.dart';
import 'auth_state.dart';

final appLanguage = computed<AppLanguage>(
  () => currentProfile.value?.language ?? AppLanguage.en,
);

/// Loading/error state for the Settings language picker
/// ([updateLanguage] in language_actions.dart).
final languageUpdateLoading = signal<bool>(false);
final languageUpdateError = signal<String?>(null);
