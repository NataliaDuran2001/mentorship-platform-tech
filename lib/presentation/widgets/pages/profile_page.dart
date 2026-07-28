// Atomic Design (Page): The user's personal dashboard to view profile details and roadmap progress.

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../state/auth_actions.dart';
import '../../state/auth_state.dart';
import '../../state/roadmap_state.dart';
import '../../utils/app_colors.dart';
import '../organisms/profile_details.dart';
import '../organisms/profile_goal_card.dart';
import '../organisms/roadmap_progress_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                RoadmapProgressCard(progress: progress),
                const SizedBox(height: 16),
                ProfileGoalCard(profile: profile, progress: progress),
                const SizedBox(height: 32),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: Text(
                      'Cerrar Sesión',
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
