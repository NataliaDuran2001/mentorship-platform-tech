// Atomic Design (Organism): Reusable functional section.
// Shared frame for the authentication screens: brand mark, title, readable
// width and scroll. Login and sign up share it so they do not look
// different.

import 'package:flutter/material.dart';

import '../../../core/config/app_branding.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background and the text styles come from the theme (AppTheme).
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxReadableWidth / 2,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Same mark as the AI roadmap-coach cue, so it reads as
                    // Kora's own touch rather than a borrowed icon.
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: AppConstants.iconTileSize,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      AppBranding.name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    // The form floats as its own panel instead of sitting
                    // directly on the page background.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLg),
                        border: Border.all(
                          color: AppColors.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.spacingLg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // headlineLg level of the design system scale.
                            Text(
                              title,
                              style:
                                  Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(
                              height: AppConstants.defaultPadding * 2,
                            ),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
