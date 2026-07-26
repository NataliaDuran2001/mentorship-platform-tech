import 'package:flutter/material.dart';
import 'core/config/app_branding.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/pages/login_page.dart';

Future<void> main() async {
  // Error de análisis deliberado para validar el AC1 del #6 (rama desechable
  // ci/validate-red, nunca se mergea): variable local sin usar.
  final int sinUsar = 42;

  // Necesario porque inicializamos plugins antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Arrancamos Supabase antes de registrar dependencias que dependen del cliente
  await SupabaseConfig.initialize();

  // Inicializamos la inyección de dependencias de get_it
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      // El tema completo vive en AppTheme; acá no se define ningún estilo.
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
