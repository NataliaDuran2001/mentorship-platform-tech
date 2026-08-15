// Atomic Design (Page): The user's personal dashboard to view profile details and roadmap progress.

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../../state/goal_actions.dart';
import '../../state/goal_state.dart';
import '../../state/language_actions.dart';
import '../../state/language_state.dart';
import '../../state/roadmap_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/translate.dart';
import '../molecules/feedback_cta_card.dart';
import '../molecules/goal_picker_sheet.dart';
import '../organisms/change_password_card.dart';
import '../organisms/language_settings_card.dart';
import '../organisms/profile_details.dart';
import '../organisms/route_overview_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Client-side checks mirror the sign-up rules; the backend re-validates.
  void _submitPasswordChange() {
    if (passwordFormNew.value.length < 6) {
      passwordUpdateError.value = tr(
        'That password is too weak. Use at least 6 characters.',
        'Esa contraseña es muy débil. Usa al menos 6 caracteres.',
      );
      return;
    }
    if (passwordFormNew.value != passwordFormConfirm.value) {
      passwordUpdateError.value = tr(
        "The new passwords don't match. Check them and try again.",
        'Las nuevas contraseñas no coinciden. Revísalas e inténtalo de '
            'nuevo.',
      );
      return;
    }
    changePassword(
      currentPassword: passwordFormCurrent.value,
      newPassword: passwordFormNew.value,
    );
  }

  void _openGoalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SignalBuilder(
          builder: (sheetContext) {
            return GoalPickerSheet(
              currentGoal: currentProfile.value?.learningGoal,
              isLoading: goalUpdateLoading.value,
              errorMessage: goalUpdateError.value,
              onSelect: (goal) async {
                await updateLearningGoal(goal);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final profile = currentProfile.value;
        if (profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = roadmapProgress.value;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                ProfileDetails(profile: profile),
                const SizedBox(height: 16),
                LanguageSettingsCard(
                  currentLanguage: appLanguage.value,
                  onSelect: updateLanguage,
                  isLoading: languageUpdateLoading.value,
                  errorMessage: languageUpdateError.value,
                ),
                const SizedBox(height: 16),
                RouteOverviewCard(
                  track: profile.track,
                  progress: progress,
                  completedCount: roadmapCompletedCount.value,
                  totalCount: roadmapLeaves.value.length,
                  goal: profile.learningGoal,
                  onEditGoal: () => _openGoalPicker(context),
                ),
                const SizedBox(height: 16),
                const FeedbackCtaCard(
                  formUrl: 'https://forms.gle/MhhuKMqibCzMDh6m9',
                ),
                const SizedBox(height: 16),
                ChangePasswordCard(
                  onCurrentChanged: (v) => passwordFormCurrent.value = v,
                  onNewChanged: (v) => passwordFormNew.value = v,
                  onConfirmChanged: (v) => passwordFormConfirm.value = v,
                  obscurePasswords: !passwordFormVisible.value,
                  onToggleObscure: () =>
                      passwordFormVisible.value = !passwordFormVisible.value,
                  isLoading: passwordUpdateLoading.value,
                  isDone: passwordUpdateDone.value,
                  errorMessage: passwordUpdateError.value,
                  onSubmit: _submitPasswordChange,
                ),
                const SizedBox(height: 32),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: Text(
                      tr('Sign out', 'Cerrar sesión'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
