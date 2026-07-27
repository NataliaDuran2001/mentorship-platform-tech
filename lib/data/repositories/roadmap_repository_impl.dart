// Capa Data: Implementación concreta del contrato RoadmapRepository contra las
// tablas `tracks`, `topics` y `user_progress` (issue #7).
//
// Devuelve los tópicos en **lista plana**, como manda el contrato: la jerarquía
// y la secuencialidad las deriva GetRoadmapTreeUseCase.

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/roadmap_track.dart';
import '../../domain/entities/topic_node.dart';
import '../../domain/entities/track.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/roadmap_repository.dart';
import '../models/topic_model.dart';

class RoadmapRepositoryImpl implements RoadmapRepository {
  const RoadmapRepositoryImpl(this._client);

  final sb.SupabaseClient _client;

  static const String _tablaTracks = 'tracks';
  static const String _tablaTopics = 'topics';
  static const String _tablaProgreso = 'user_progress';

  @override
  Future<List<Track>> listTracks() {
    return _traducir(() async {
      final filas = await _client
          .from(_tablaTracks)
          .select('id, name, description, icon_name')
          .order('sort_order');

      return filas
          .map((fila) {
            final id = RoadmapTrack.fromSlug(fila['id'] as String?);
            if (id == null) return null;
            return Track(
              id: id,
              name: fila['name'] as String? ?? '',
              description: fila['description'] as String? ?? '',
              iconName: fila['icon_name'] as String?,
            );
          })
          .whereType<Track>()
          .toList(growable: false);
    });
  }

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) {
    return _traducir(() async {
      final filas = await _client
          .from(_tablaTopics)
          .select(TopicModel.columns)
          .eq('track_id', track.slug)
          .order('sort_order');

      // Dos consultas y no un join: `user_progress` está protegida por RLS a las
      // filas de la usuaria, así que traer solo los tópicos completados es una
      // lista corta y evita que el join arrastre el avance de nadie más.
      final completados = await _idsCompletados();

      return filas
          .map(
            (fila) => TopicModel.fromJson(fila).toEntity(
              isCompleted: completados.contains(fila['id'] as String),
            ),
          )
          .whereType<TopicNode>()
          .toList(growable: false);
    });
  }

  Future<Set<String>> _idsCompletados() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return <String>{};

    final filas = await _client
        .from(_tablaProgreso)
        .select('topic_id')
        .eq('user_id', id)
        .eq('status', 'completed');

    return filas.map((fila) => fila['topic_id'] as String).toSet();
  }

  /// Traduce los errores del backend a AuthFailure, igual que los otros
  /// repositorios: presentation no importa supabase_flutter.
  Future<T> _traducir<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on sb.PostgrestException catch (e) {
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
