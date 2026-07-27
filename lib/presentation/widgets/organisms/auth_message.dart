// Atomic Design (Organismo): Sección funcional reutilizable.
// Cartel de error o de aviso de las pantallas de autenticación.
//
// Recibe el texto ya traducido al español. Nunca recibe una excepción: la capa
// Data traduce la excepción de Supabase a un AuthFailure y
// utils/auth_error_messages.dart lo convierte en texto. Así ningún error crudo
// del backend puede llegar a la pantalla ni por descuido.

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

enum AuthMessageTone { error, info }

class AuthMessage extends StatelessWidget {
  const AuthMessage({
    super.key,
    required this.message,
    this.tone = AuthMessageTone.error,
  });

  final String message;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final esError = tone == AuthMessageTone.error;
    final fondo = esError ? AppColors.errorContainer : AppColors.primaryFixed;
    final texto =
        esError ? AppColors.onErrorContainer : AppColors.onPrimaryFixed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppConstants.radiusDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.mark_email_unread_outlined,
            color: texto,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: texto),
            ),
          ),
        ],
      ),
    );
  }
}
