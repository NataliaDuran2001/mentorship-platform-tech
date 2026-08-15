// Presentation layer (State): State for AI features (Daily Brief, Roadmap Coach, hints).
//
// Declarations of signals. The actions are in ai_actions.dart.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/app_language.dart';

// --- Daily Brief (Module 2) ---
final dailyBrief = signal<String?>(null);
final dailyBriefLoading = signal<bool>(false);
final dailyBriefError = signal<String?>(null);

/// The language [dailyBrief] was generated in. Compared against `appLanguage`
/// so a Settings language switch refetches instead of leaving a stale-language
/// brief on screen — the edge function itself caches per language, but
/// nothing previously told the client its in-memory copy had gone stale.
final dailyBriefLanguage = signal<AppLanguage?>(null);

// --- Roadmap Coach (Module 3) ---
final roadmapCoachMessage = signal<String?>(null);
final roadmapCoachLoading = signal<bool>(false);
final roadmapCoachError = signal<String?>(null);
final roadmapCoachLanguage = signal<AppLanguage?>(null);

// --- Welcome Message (dashboard header) ---
final welcomeMessage = signal<String?>(null);
final welcomeMessageLoading = signal<bool>(false);
final welcomeMessageError = signal<String?>(null);
final welcomeMessageLanguage = signal<AppLanguage?>(null);

// --- Lab Hints Cache (Module 4) ---
// Key is topicId. Value is the list of generated hints so far for the current challenge
final labHints = signal<Map<String, List<String>>>(const {});
final labHintLoading = signal<bool>(false);
final labHintError = signal<String?>(null);

/// Resets all AI states (called on logout/reset)
void resetAiState() {
  dailyBrief.value = null;
  dailyBriefLoading.value = false;
  dailyBriefError.value = null;
  dailyBriefLanguage.value = null;

  roadmapCoachMessage.value = null;
  roadmapCoachLoading.value = false;
  roadmapCoachError.value = null;
  roadmapCoachLanguage.value = null;

  welcomeMessage.value = null;
  welcomeMessageLoading.value = false;
  welcomeMessageError.value = null;
  welcomeMessageLanguage.value = null;

  labHints.value = const {};
  labHintLoading.value = false;
  labHintError.value = null;
}
