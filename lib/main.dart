import 'package:flutter/material.dart';

import 'core/config/app_branding.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/state/auth_actions.dart';
import 'presentation/utils/app_colors.dart';
import 'presentation/utils/constants.dart';

Future<void> main() async {
  // Necesario porque inicializamos plugins antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Arrancamos Supabase antes de registrar dependencias que dependen del
    // cliente.
    await SupabaseConfig.initialize();

    // Inicializamos la inyección de dependencias de get_it.
    setupDependencies();

    // Restaura la sesión persistida y trae el perfil antes de montar la UI, de
    // modo que los route guards nunca decidan con el perfil a medio cargar.
    await bootstrapAuth();
  } catch (e) {
    // Sin este catch, cualquier fallo del backend dejaba una pantalla blanca
    // indefinida y sin diagnóstico: era la deuda 2 de la §3 del handoff.
    runApp(ArranqueFallido(detalle: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      // El tema completo vive en AppTheme; acá no se define ningún estilo.
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}

/// Pantalla de último recurso cuando la app no puede arrancar.
///
/// Muestra un mensaje en español y deja el detalle técnico a la vista: acá no
/// hay una usuaria a la que proteger del error crudo, hay alguien mirando una
/// app que no arrancó y que necesita saber por qué.
class ArranqueFallido extends StatelessWidget {
  const ArranqueFallido({super.key, required this.detalle});

  final String detalle;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: AppConstants.iconTileSize,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  'No pudimos iniciar la aplicación',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'Revisá tu conexión y volvé a abrirla. Si el problema sigue, '
                  'el servicio puede estar caído.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingLg),
                SelectableText(detalle, style: AppTheme.code),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
