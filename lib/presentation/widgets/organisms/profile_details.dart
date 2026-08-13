// Atomic Design (Organism): Displays the user's identity details as a header card.

import 'package:flutter/material.dart';

import '../../../domain/entities/user_profile.dart';
import '../../utils/app_colors.dart';
import '../../utils/onboarding_labels.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName?.isNotEmpty == true
        ? profile.displayName!
        : profile.email.split('@').first;
    
    final trackStr = trackName(profile.track) ?? 'No focus yet';
    final levelStr = levelName(profile.experienceLevel) ?? 'No level yet';
    final subtitle = '$trackStr · $levelStr';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceContainerHighest),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: null, // Disabled in MVP
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Edit profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
