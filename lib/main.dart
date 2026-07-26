import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'presentation/widgets/pages/login_page.dart';
import 'presentation/utils/app_colors.dart';

Future<void> main() async {
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
      title: 'Mentorship App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        // Si no has agregado la fuente a pubspec.yaml, usará la fuente por defecto del sistema
        fontFamily: 'Geist',
      ),
      home: const LoginPage(),
    );
  }
}
