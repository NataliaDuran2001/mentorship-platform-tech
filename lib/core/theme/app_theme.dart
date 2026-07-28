// Core layer (Theme): the app's single ThemeData, built from the
// AppColors/AppConstants tokens (frontmatter of DESIGN.md). The component
// specifications come from the prose of DESIGN.md, which for components is the
// source; its hex values are not.

import 'package:flutter/material.dart';

import '../../presentation/utils/app_colors.dart';
import '../../presentation/utils/constants.dart';

class AppTheme {
  // `code` level of the typographic scale. TextTheme has no slot for code, so
  // it is exposed here. It uses GeistMono and not Geist (which is what the
  // frontmatter declares): GeistMono-Regular is the only mono .ttf the design
  // system asks to register and its prose asks to distinguish code blocks from
  // running text. Decision recorded in §9 of handoff B.
  static const TextStyle code = TextStyle(
    fontFamily: 'GeistMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    color: AppColors.onSurface,
  );

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      primaryFixed: AppColors.primaryFixed,
      primaryFixedDim: AppColors.primaryFixedDim,
      onPrimaryFixed: AppColors.onPrimaryFixed,
      onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
      inversePrimary: AppColors.inversePrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      secondaryFixed: AppColors.secondaryFixed,
      secondaryFixedDim: AppColors.secondaryFixedDim,
      onSecondaryFixed: AppColors.onSecondaryFixed,
      onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      tertiaryFixed: AppColors.tertiaryFixed,
      tertiaryFixedDim: AppColors.tertiaryFixedDim,
      onTertiaryFixed: AppColors.onTertiaryFixed,
      onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceDim: AppColors.surfaceDim,
      surfaceBright: AppColors.surfaceBright,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      surfaceTint: AppColors.surfaceTint,
    );

    // Typographic scale from the frontmatter. height = lineHeight / fontSize;
    // letterSpacing in em converted to logical pixels (em × fontSize).
    const textTheme = TextTheme(
      // headlineLg: 32 / 600 / lh 40 / -0.02em
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.64,
      ),
      // headlineMd: 24 / 600 / lh 32 / -0.01em
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.24,
      ),
      // headlineSm: 20 / 500 / lh 28
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 28 / 20,
      ),
      // bodyLg: 16 / 400 / lh 24
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      // bodyMd: 14 / 400 / lh 20
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      // labelMd: 12 / 500 / lh 16 / 0.02em
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.24,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
    );
    const buttonPadding = EdgeInsets.symmetric(
      vertical: AppConstants.spacingMd,
      horizontal: AppConstants.spacingLg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Single declaration of the family: widgets do not repeat it.
      fontFamily: 'Geist',
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
      // Shell nav: light background, no scroll tint, indicator in the light
      // fixed violet of the palette.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.primaryFixed,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onPrimaryFixed);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: AppColors.onSurfaceVariant);
        }),
      ),
      // Primary button: primary background, white text, radius 8, no shadow.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      // Secondary button: transparent, 1px border, dark text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      // Ghost button: no background nor border, violet text.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      // Inputs: white background, 1px border; on focus the border turns
      // primary. The 2px glow at 20% lives in CustomInput: an InputBorder
      // cannot paint shadows.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        prefixIconColor: AppColors.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      // Cards: defined by a 1px border, not by a shadow. (The slight hover
      // shadow is not themeable; it goes in the interactive widget that needs
      // it.)
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      // Chips: pill, light grey background, slate text.
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
        shape: StadiumBorder(),
        side: BorderSide.none,
      ),
      // Selected list item: violet tint at 5% and primary text. (The 2px
      // active vertical bar is not themeable; it goes in the widget.)
      listTileTheme: ListTileThemeData(
        selectedTileColor: AppColors.primary.withValues(alpha: 0.05),
        selectedColor: AppColors.primary,
      ),
    );
  }
}
