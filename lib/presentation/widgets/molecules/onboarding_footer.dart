// Atomic Design (Molécula): Combina átomos para formar un bloque funcional.
// La barra de acciones del onboarding: Regresar · Omitir · Continuar.
//
// La visibilidad de cada botón entra por parámetro. La regla de cuándo
// mostrarlos NO vive acá: que «Omitir» esté prohibido en el paso 2 —sin track
// no hay roadmap, CA 1.3— es del issue #11, que es quien conoce el paso.
//
// «Regresar» oculto conserva su espacio (el `invisible` del prototipo, no un
// `display:none`): así «Continuar» no se corre de lugar entre pasos.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../atoms/custom_button.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.onContinue,
    this.onBack,
    this.onSkip,
    this.showBack = true,
    this.showSkip = true,
    this.continueLabel = 'Continuar',
  });

  /// `null` deshabilita el botón: es como el paso 2 impide avanzar sin elegir.
  final VoidCallback? onContinue;

  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  final bool showBack;
  final bool showSkip;

  /// El último paso dice «Entrar al Dashboard» en vez de «Continuar».
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final regresar = Visibility(
      visible: showBack,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: _BotonGhost(
        label: 'Regresar',
        onPressed: showBack ? onBack : null,
      ),
    );

    final omitir = showSkip
        ? _BotonGhost(label: 'Omitir', onPressed: onSkip)
        : const SizedBox.shrink();

    final continuar = CustomButton(
      text: continueLabel,
      onPressed: onContinue,
      isPrimary: true,
    );

    // En móvil los tres botones no caben en una fila —«Entrar al Dashboard» es
    // largo—, así que la acción principal pasa a ocupar todo el ancho arriba y
    // las secundarias quedan debajo. Se mide el ancho del pie y no el de la
    // ventana, porque el pie vive dentro de un panel con márgenes.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppConstants.footerCompactWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              continuar,
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [regresar, omitir],
              ),
            ],
          );
        }

        return Row(
          children: [
            regresar,
            const Spacer(),
            if (showSkip)
              Padding(
                padding: const EdgeInsets.only(right: AppConstants.spacingSm),
                child: omitir,
              ),
            continuar,
          ],
        );
      },
    );
  }
}

/// Botón fantasma del prototipo: sin fondo ni borde, texto atenuado.
///
/// No usa CustomButton porque su variante secundaria es un OutlinedButton, que
/// sí lleva borde. El `textButtonTheme` del tema es la variante ghost del
/// design system, pero pinta el texto en `primary`; en el pie del onboarding
/// las dos acciones secundarias van en `onSurfaceVariant` para no competir con
/// «Continuar». Extraer una variante ghost de CustomButton queda anotado para
/// cuando el #9 toque los botones del login.
class _BotonGhost extends StatelessWidget {
  const _BotonGhost({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }
}
