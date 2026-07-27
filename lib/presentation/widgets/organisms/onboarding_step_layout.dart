// Atomic Design (Organismo): Sección funcional reutilizable.
// El marco común de todos los pasos del onboarding: barra de progreso,
// contador, título, subtítulo, contenido y pie de acciones, más la columna
// decorativa de escritorio.
//
// No está en la lista de organismos del issue #11, y existe porque la
// alternativa era que los cuatro pasos —cinco con el cuestionario guía del
// #12— repitieran el mismo encabezado y pie. Cada copia es una oportunidad de
// que un paso se vea distinto.
//
// No lee estado: recibe el número de paso, el total y las visibilidades. Quien
// las calcula es OnboardingPage.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/app_progress_bar.dart';
import '../atoms/step_counter_label.dart';
import '../molecules/onboarding_footer.dart';

class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.onSkip,
    this.onContinue,
    this.showBack = true,
    this.showSkip = true,
    this.continueLabel = 'Continuar',
    this.errorMessage,
  });

  final int currentStep;
  final int totalSteps;

  /// Encabezado del paso. `null` o vacío cuando el contenido trae el suyo, como
  /// el resumen con su ícono de confirmación.
  final String? title;

  final String? subtitle;
  final Widget child;

  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;
  final bool showBack;
  final bool showSkip;
  final String continueLabel;

  /// Ya traducido al español.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final esEscritorio =
        MediaQuery.sizeOf(context).width > AppConstants.breakpointTablet;

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppProgressBar(
          value: currentStep / totalSteps,
          semanticsLabel: 'Paso $currentStep de $totalSteps',
        ),
        const SizedBox(height: AppConstants.spacingMd),
        StepCounterLabel(currentStep: currentStep, totalSteps: totalSteps),
        const SizedBox(height: AppConstants.spacingLg),
        if (title != null && title!.isNotEmpty)
          Text(title!, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        child,
        if (errorMessage != null) ...[
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            errorMessage!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppConstants.spacingXl),
        OnboardingFooter(
          onBack: onBack,
          onSkip: onSkip,
          onContinue: onContinue,
          showBack: showBack,
          showSkip: showSkip,
          continueLabel: continueLabel,
        ),
      ],
    );

    final panel = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: AppConstants.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: esEscritorio
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2/5 del ancho para la columna decorativa, como el prototipo.
                const Expanded(flex: 2, child: _PanelDecorativo()),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingXl),
                    child: SingleChildScrollView(child: contenido),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: SingleChildScrollView(child: contenido),
            ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.containerMax,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Columna izquierda de escritorio.
///
/// El prototipo pone acá una ilustración; el repositorio todavía no tiene ese
/// asset, así que se resuelve con los tokens del design system en vez de
/// referenciar un archivo que no existe. Reemplazable sin tocar nada más.
class _PanelDecorativo extends StatelessWidget {
  const _PanelDecorativo();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.explore_outlined,
              color: AppColors.onPrimary,
              size: AppConstants.iconTileSize,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              'Tu futuro empieza acá',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Te acompañamos en cada paso de tu carrera tecnológica, con '
              'claridad y empatía.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
