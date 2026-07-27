// Capa Core: Configuración de la inyección de dependencias con get_it.
// Acá se registran los repositorios, casos de uso y otros servicios.
//
// Ningún widget construye un repositorio ni un caso de uso: los saca de getIt.
// Los repositorios se registran contra su contrato de `domain`, no contra la
// clase concreta, para que la capa Presentation nunca dependa de `data`.

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/recommend_track_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/submit_onboarding_usecase.dart';
import '../config/supabase_config.dart';

final getIt = GetIt.instance;

/// Requiere que SupabaseConfig.initialize() ya se haya ejecutado.
///
/// Es idempotente: volver a llamarla no duplica registros. Lo necesitan los
/// tests, que montan la app más de una vez en el mismo proceso.
void setupDependencies() {
  if (getIt.isRegistered<AuthRepository>()) return;

  // Cliente de Supabase: única puerta de entrada al backend desde la capa Data.
  getIt.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  // Repositorios, registrados contra el contrato de domain.
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(getIt<SupabaseClient>()),
  );

  // Casos de uso.
  getIt.registerLazySingleton(() => SignUpUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignInUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => SubmitOnboardingUseCase(getIt<OnboardingRepository>()),
  );
  // Sin dependencias: es lógica pura sobre las respuestas del cuestionario.
  getIt.registerLazySingleton(() => const RecommendTrackUseCase());
}

/// Registra dependencias ya construidas, para los tests.
///
/// Permite montar la app con dobles de prueba sin tocar Supabase.
void overrideDependency<T extends Object>(T instancia) {
  if (getIt.isRegistered<T>()) getIt.unregister<T>();
  getIt.registerSingleton<T>(instancia);
}
