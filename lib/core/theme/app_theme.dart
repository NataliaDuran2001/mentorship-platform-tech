// Capa Core (Theme): ThemeData único de la app, construido desde los tokens
// de AppColors/AppConstants (frontmatter de DESIGN.md). Las especificaciones
// de componentes vienen de la prosa de DESIGN.md, que para componentes sí es
// la fuente; sus valores hex no lo son.

import 'package:flutter/material.dart';

import '../../presentation/utils/app_colors.dart';
import '../../presentation/utils/constants.dart';

class AppTheme {
  // Nivel `code` de la escala tipográfica. TextTheme no tiene slot para
  // código, así que se expone acá. Usa GeistMono y no Geist (que es lo que
  // declara el frontmatter): GeistMono-Regular es el único .ttf mono que el
  // design system manda a registrar y su prosa pide distinguir los bloques de
  // código del texto corrido. Decisión anotada en la §9 del handoff B.
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

    // Escala tipográfica del frontmatter. height = lineHeight / fontSize;
    // letterSpacing en em convertido a píxeles lógicos (em × fontSize).
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
      // Única declaración de la familia: los widgets no la repiten.
      fontFamily: 'Geist',
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
      // Botón primario: fondo primary, texto blanco, radio 8, sin sombra.
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
      // Botón secundario: transparente, borde de 1px, texto oscuro.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      // Botón ghost: sin fondo ni borde, texto violeta.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      // Inputs: fondo blanco, borde de 1px; al foco el borde pasa a primary.
      // El glow de 2px al 20% vive en CustomInput: un InputBorder no puede
      // pintar sombras.
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
      // Cards: definidas por borde de 1px, no por sombra. (La sombra leve de
      // hover no es tematizable; va en el widget interactivo que la necesite.)
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      // Chips: pill, fondo gris claro, texto slate.
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
        shape: StadiumBorder(),
        side: BorderSide.none,
      ),
      // Ítem de lista seleccionado: tinte violeta al 5% y texto primary. (La
      // barra vertical activa de 2px no es tematizable; va en el widget.)
      listTileTheme: ListTileThemeData(
        selectedTileColor: AppColors.primary.withValues(alpha: 0.05),
        selectedColor: AppColors.primary,
      ),
    );
  }
}
