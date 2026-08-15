// Atomic Design (Molecule): Beta-feedback invite — a static card asking the
// learner to fill an external form, with an optional QR code image pointing
// at the same link. Self-contained on purpose (no signals, no state) so it
// can be dropped from Profile in one line once the beta closes.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/translate.dart';
import '../atoms/custom_button.dart';

class FeedbackCtaCard extends StatelessWidget {
  const FeedbackCtaCard({super.key, required this.formUrl, this.qrAssetPath});

  /// Link to the external feedback form.
  final String formUrl;

  /// Optional asset path to a QR image pointing at [formUrl]. When `null`,
  /// only the button is shown.
  final String? qrAssetPath;

  Future<void> _openForm() =>
      launchUrl(Uri.parse(formUrl), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        side: const BorderSide(color: AppColors.surfaceContainerHighest),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_outline,
              color: AppColors.primary,
              size: AppConstants.iconSizeLg,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              tr('Help us improve Kora!', '¡Ayúdanos a mejorar Kora!'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              tr(
                'You are one of our first 30 testers. A short survey helps '
                    'us shape what comes next.',
                'Eres una de nuestras primeras 30 personas en probar Kora. '
                    'Una encuesta breve nos ayuda a definir lo que sigue.',
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            if (qrAssetPath != null) ...[
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Image.asset(qrAssetPath!),
              ),
              const SizedBox(height: AppConstants.spacingLg),
            ],
            CustomButton(
              text: tr('Give feedback', 'Dar mi opinión'),
              icon: const Icon(Icons.arrow_outward),
              onPressed: _openForm,
            ),
          ],
        ),
      ),
    );
  }
}
