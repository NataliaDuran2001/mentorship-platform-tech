// Core layer: Dependency injection setup with get_it.
// Repositories, use cases and other services are registered here.
//
// No widget builds a repository or a use case: they take them from getIt.
// Repositories are registered against their `domain` contract, not against the
// concrete class, so that the Presentation layer never depends on `data`.

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../data/repositories/roadmap_repository_impl.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/interview_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/roadmap_repository.dart';
import '../../domain/repositories/lab_repository.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/interview_repository.dart';
import '../../data/repositories/lab_repository_impl.dart';
import '../../domain/usecases/complete_topic_usecase.dart';
import '../../domain/usecases/get_roadmap_tree_usecase.dart';
import '../../domain/usecases/recommend_track_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/submit_onboarding_usecase.dart';
import '../config/supabase_config.dart';

final getIt = GetIt.instance;

/// Requires SupabaseConfig.initialize() to have already run.
///
/// It is idempotent: calling it again does not duplicate registrations. The
/// tests need that, since they mount the app more than once in the same
/// process.
void setupDependencies() {
  if (getIt.isRegistered<AuthRepository>()) return;

  // Supabase client: the single entry point to the backend from the Data
  // layer.
  getIt.registerLazySingleton<SupabaseClient>(() => SupabaseConfig.client);

  // Repositories, registered against the domain contract.
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<RoadmapRepository>(
    () => RoadmapRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<LabRepository>(
    () => LabRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<InterviewRepository>(
    () => InterviewRepositoryImpl(getIt<SupabaseClient>()),
  );

  // Use cases.
  getIt.registerLazySingleton(() => SignUpUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignInUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => SubmitOnboardingUseCase(getIt<OnboardingRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetRoadmapTreeUseCase(getIt<RoadmapRepository>()),
  );
  getIt.registerLazySingleton(
    () => CompleteTopicUseCase(getIt<RoadmapRepository>()),
  );
  // RecommendTrackUseCase now requires AiRepository (tries Kimi3 first,
  // falls back to the deterministic vote-count rule on failure).
  getIt.registerLazySingleton(
    () => RecommendTrackUseCase(getIt<AiRepository>()),
  );
}

/// Registers already built dependencies, for the tests.
///
/// It allows mounting the app with test doubles without touching Supabase.
void overrideDependency<T extends Object>(T instance) {
  if (getIt.isRegistered<T>()) getIt.unregister<T>();
  getIt.registerSingleton<T>(instance);
}
