// Atomic Design (Organism): Reusable functional section.
//
// The Settings language picker (English/Español) on the profile page. Like
// ChangePasswordCard, it reads no signals and resolves nothing: it takes the
// current language, a callback and already user-facing messages;
// ProfilePage wires it to the state.

import 'package:flutter/material.dart';

import '../../../domain/entities/app_language.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../molecules/language_segmented_control.dart';
import 'auth_message.dart';

class LanguageSettingsCard extends StatelessWidget {
  const LanguageSettingsCard({
    super.key,
    required this.currentLanguage,
    required this.onSelect,
    required this.isLoading,
    this.errorMessage,
  });

  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onSelect;
  final bool isLoading;

  /// Already user-facing text. `null` when there is no error.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Settings', 'Configuración'),
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              tr('Language', 'Idioma'),
              style: textTheme.labelLarge
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            if (errorMessage != null) ...[
              AuthMessage(message: errorMessage!),
              const SizedBox(height: AppConstants.spacingSm),
            ],
            LanguageSegmentedControl(
              currentLanguage: currentLanguage,
              onSelect: onSelect,
              isLoading: isLoading,
            ),
            if (isLoading) ...[
              const SizedBox(height: AppConstants.spacingSm),
              const Center(
                child: SizedBox(
                  width: AppConstants.iconSizeSm,
                  height: AppConstants.iconSizeSm,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
