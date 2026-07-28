// Presentation layer (Utils): Color palette of the Luminous Clarity design
// system. Source of truth: the YAML frontmatter of DESIGN.md, with its
// camelCase names. The hex values in that document's prose are NOT
// authoritative: they are where the drifted values this version fixes came
// from.

import 'package:flutter/material.dart';

class AppColors {
  // Surfaces
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF494552);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color outline = Color(0xFF7A7583);
  static const Color outlineVariant = Color(0xFFCAC4D4);
  static const Color surfaceTint = Color(0xFF674BB5);

  // Primary
  static const Color primary = Color(0xFF674BB5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFA78BFA);
  static const Color onPrimaryContainer = Color(0xFF3C1989);
  static const Color inversePrimary = Color(0xFFCEBDFF);
  static const Color primaryFixed = Color(0xFFE8DDFF);
  static const Color primaryFixedDim = Color(0xFFCEBDFF);
  static const Color onPrimaryFixed = Color(0xFF21005E);
  static const Color onPrimaryFixedVariant = Color(0xFF4F319C);

  // Secondary
  static const Color secondary = Color(0xFF712AE2);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF8A4CFC);
  static const Color onSecondaryContainer = Color(0xFFFFFBFF);
  static const Color secondaryFixed = Color(0xFFEADDFF);
  static const Color secondaryFixedDim = Color(0xFFD2BBFF);
  static const Color onSecondaryFixed = Color(0xFF25005A);
  static const Color onSecondaryFixedVariant = Color(0xFF5A00C6);

  // Tertiary
  static const Color tertiary = Color(0xFF6A5F00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFAF9E00);
  static const Color onTertiaryContainer = Color(0xFF3B3500);
  static const Color tertiaryFixed = Color(0xFFF8E454);
  static const Color tertiaryFixedDim = Color(0xFFDBC839);
  static const Color onTertiaryFixed = Color(0xFF201C00);
  static const Color onTertiaryFixedVariant = Color(0xFF504700);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Success (Added for Learning Engine feedback)
  static const Color success = Color(0xFF198754);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD1E7DD);
  static const Color onSuccessContainer = Color(0xFF0A3622);

  // Background (in this design system it matches surface/onSurface)
  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);
}
