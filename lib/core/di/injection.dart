// Capa Core: Archivo para configurar la inyección de dependencias usando get_it.
// Aquí se registran los repositorios, casos de uso, y otros servicios.

import 'package:get_it/get_it.dart';
// import '../../domain/repositories/auth_repository.dart';
// import '../../data/repositories/auth_repository_impl.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Ejemplo de inyección:
  // getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
}
