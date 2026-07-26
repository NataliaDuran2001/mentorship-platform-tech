// Capa Core: Archivo para configurar la inyección de dependencias usando get_it.
// Aquí se registran los repositorios, casos de uso, y otros servicios.

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
// import '../../domain/repositories/auth_repository.dart';
// import '../../data/repositories/auth_repository_impl.dart';

final getIt = GetIt.instance;

/// Requiere que SupabaseConfig.initialize() ya se haya ejecutado.
void setupDependencies() {
  // Cliente de Supabase: única puerta de entrada al backend desde la capa Data.
  getIt.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  // Ejemplo de inyección:
  // getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<SupabaseClient>()));
}
