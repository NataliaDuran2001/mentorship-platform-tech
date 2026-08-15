// Presentation layer (State): Learning goal editing, from the Profile page.
//
// Mirrors language_state.dart: loading/error signals for a single-field
// update, read by whatever UI drives updateLearningGoal (goal_actions.dart).

import 'package:signals_flutter/signals_flutter.dart';

final goalUpdateLoading = signal<bool>(false);
final goalUpdateError = signal<String?>(null);
