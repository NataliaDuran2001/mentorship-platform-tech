// Capa Data: Modelo que parsea la información desde/hacia la base de datos y
// se mapea a la entidad UserProfile de la capa Domain.
//
// Las claves son los nombres de columna de `public.profiles`, tal como los
// creó la migración del issue #7. Los valores de `experience_level`,
// `track_id` y `learning_goal` son los slugs de los enums de `domain`, así que
// el mapeo es directo y no necesita tabla de traducción.

import '../../domain/entities/experience_level.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/user_profile.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.experienceLevel,
    this.trackId,
    this.learningGoal,
    this.onboardingCompletedAt,
  });

  /// Columnas que se piden en un `select`. Explícitas y no `*` para que
  /// agregar una columna a la tabla no cambie en silencio lo que viaja al
  /// cliente.
  static const String columns =
      'id, email, display_name, experience_level, track_id, learning_goal, '
      'onboarding_completed_at';

  final String id;
  final String email;
  final String? displayName;
  final String? experienceLevel;
  final String? trackId;
  final String? learningGoal;
  final DateTime? onboardingCompletedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      // El trigger copia el correo de auth.users, así que en la práctica nunca
      // es null; el fallback evita que una fila vieja rompa la lectura.
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      experienceLevel: json['experience_level'] as String?,
      trackId: json['track_id'] as String?,
      learningGoal: json['learning_goal'] as String?,
      onboardingCompletedAt: _parseFecha(json['onboarding_completed_at']),
    );
  }

  factory UserModel.fromEntity(UserProfile profile) {
    return UserModel(
      id: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      experienceLevel: profile.experienceLevel?.slug,
      trackId: profile.track?.slug,
      learningGoal: profile.learningGoal?.slug,
      onboardingCompletedAt: profile.onboardingCompletedAt,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      // Un slug desconocido se lee como null en vez de romper: una fila
      // escrita por una versión más nueva de la app no debe dejar a la usuaria
      // sin poder entrar.
      experienceLevel: ExperienceLevel.fromSlug(experienceLevel),
      track: RoadmapTrack.fromSlug(trackId),
      learningGoal: LearningGoal.fromSlug(learningGoal),
      onboardingCompletedAt: onboardingCompletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'experience_level': experienceLevel,
      'track_id': trackId,
      'learning_goal': learningGoal,
      'onboarding_completed_at': onboardingCompletedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseFecha(Object? valor) {
    if (valor is String) return DateTime.tryParse(valor);
    if (valor is DateTime) return valor;
    return null;
  }
}
