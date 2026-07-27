// Capa Data: Implementación concreta del contrato OnboardingRepository contra
// las tablas `profiles` y `onboarding_answers` (issue #7).
//
// Toma el SupabaseClient de getIt. Todas las consultas van implícitamente
// filtradas por RLS a las filas de la usuaria autenticada: el `eq('user_id',
// …)` explícito está igual, porque una consulta que depende solo de la política
// para no traer datos ajenos es frágil de leer.
//
// Se implementa completa acá y no repartida entre #9, #11 y #14 porque es una
// sola clase: los route guards del #9 necesitan `loadProfile()`, y dejar los
// otros tres métodos lanzando obligaría a volver a esta clase dos veces más.
// Decisión anotada en la §9 del handoff.

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/onboarding_answer.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../models/user_model.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._client);

  final sb.SupabaseClient _client;

  static const String _tablaPerfiles = 'profiles';
  static const String _tablaRespuestas = 'onboarding_answers';

  @override
  Future<UserProfile?> loadProfile() async {
    final id = _idUsuaria;
    if (id == null) return null;

    return _traducir(() async {
      final fila = await _client
          .from(_tablaPerfiles)
          .select(UserModel.columns)
          .eq('id', id)
          .maybeSingle();

      // null si el trigger no alcanzó a crear el perfil todavía. Quien llama
      // decide si reintenta; no se inventa un perfil vacío.
      if (fila == null) return null;
      return UserModel.fromJson(fila).toEntity();
    });
  }

  @override
  Future<void> saveAnswer(OnboardingAnswer answer) async {
    final id = _idExigido;

    await _traducir(() async {
      // Upsert por (user_id, step_key), que es la constraint única de la tabla:
      // cambiar una respuesta al volver atrás actualiza la fila en vez de
      // agregar otra. Es lo que hace reanudable el flujo (#14).
      await _client.from(_tablaRespuestas).upsert(
        <String, dynamic>{
          'user_id': id,
          'step_key': answer.stepKey,
          'value': answer.value,
          'answered_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id, step_key',
      );
    });
  }

  @override
  Future<List<OnboardingAnswer>> loadAnswers() async {
    final id = _idUsuaria;
    if (id == null) return const <OnboardingAnswer>[];

    return _traducir(() async {
      final filas = await _client
          .from(_tablaRespuestas)
          .select('step_key, value, answered_at')
          .eq('user_id', id);

      return filas
          .map(
            (fila) => OnboardingAnswer(
              stepKey: fila['step_key'] as String,
              value: fila['value'] as String,
              answeredAt: DateTime.tryParse(
                fila['answered_at'] as String? ?? '',
              ),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<UserProfile> completeOnboarding({
    required RoadmapTrack track,
    ExperienceLevel? experienceLevel,
    LearningGoal? learningGoal,
  }) async {
    final id = _idExigido;

    return _traducir(() async {
      final fila = await _client
          .from(_tablaPerfiles)
          .update(<String, dynamic>{
            'experience_level': experienceLevel?.slug,
            'track_id': track.slug,
            'learning_goal': learningGoal?.slug,
            'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select(UserModel.columns)
          .single();

      return UserModel.fromJson(fila).toEntity();
    });
  }

  // ---------------------------------------------------------------------------

  String? get _idUsuaria => _client.auth.currentUser?.id;

  /// Igual que [_idUsuaria] pero falla si no hay sesión, para las escrituras.
  ///
  /// Sin sesión la política RLS rechazaría la fila igual, pero con un error de
  /// Postgres que no dice nada útil. Mejor fallar acá y con un caso conocido.
  String get _idExigido {
    final id = _idUsuaria;
    if (id == null) {
      throw const AuthFailure(
        AuthFailureKind.invalidCredentials,
        technicalDetail: 'No hay sesión activa al escribir el onboarding',
      );
    }
    return id;
  }

  /// Traduce los errores del backend a AuthFailure, igual que
  /// AuthRepositoryImpl: presentation no importa supabase_flutter.
  Future<T> _traducir<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthFailure {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } on sb.AuthException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      final texto = e.toString().toLowerCase();
      final deRed = texto.contains('socketexception') ||
          texto.contains('clientexception') ||
          texto.contains('failed host lookup') ||
          texto.contains('connection') ||
          texto.contains('timeout') ||
          texto.contains('xmlhttprequest');

      throw AuthFailure(
        deRed ? AuthFailureKind.network : AuthFailureKind.unknown,
        technicalDetail: e.toString(),
      );
    }
  }
}
