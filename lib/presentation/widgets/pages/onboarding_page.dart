// Atomic Design (Página): Placeholder del onboarding del Módulo 1. Vive fuera
// del shell — sin nav visible —, como manda el issue #5. El flujo real de 4
// pasos y resumen llega con E1 (#11).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../atoms/custom_button.dart';
import '../../utils/constants.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppConstants.maxReadableWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Onboarding',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Text(
                    'El flujo de onboarding del Módulo 1 —4 pasos y resumen— llega con E1 (#11).',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingXl),
                  CustomButton(
                    text: 'Continuar al dashboard',
                    onPressed: () => context.go('/dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
