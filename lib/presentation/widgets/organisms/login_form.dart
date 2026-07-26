// Atomic Design (Organismo): Conjunto de moléculas y átomos que forman 
// una sección funcional completa e independiente dentro de una página.

import 'package:flutter/material.dart';
import '../atoms/custom_input.dart';
import '../atoms/custom_button.dart';
import '../molecules/google_login_button.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class LoginForm extends StatelessWidget {
  final VoidCallback onLoginWithGoogle;
  final VoidCallback onLogin;

  const LoginForm({
    super.key, 
    required this.onLoginWithGoogle,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CustomInput(hintText: 'Correo electrónico', prefixIcon: Icons.email),
        const SizedBox(height: AppConstants.defaultPadding),
        const CustomInput(hintText: 'Contraseña', prefixIcon: Icons.lock, obscureText: true),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        CustomButton(text: 'Ingresar', onPressed: onLogin),
        
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Text("O", style: TextStyle(color: AppColors.onSurfaceVariant)),
            ),
            Expanded(child: Divider()),
          ]
        ),
        const SizedBox(height: AppConstants.defaultPadding * 1.5),
        
        GoogleLoginButton(onPressed: onLoginWithGoogle),
      ],
    );
  }
}
