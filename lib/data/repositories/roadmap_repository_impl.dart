// Data layer: Concrete implementation of the RoadmapRepository contract
// against the `tracks`, `topics` and `user_progress` tables (issue #7).
//
// It returns the topics as a **flat list**, as the contract mandates: the
// hierarchy and the sequencing are derived by GetRoadmapTreeUseCase.

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

  static const String _tracksTable = 'tracks';
  static const String _topicsTable = 'topics';
  static const String _progressTable = 'user_progress';

  @override
  Future<List<Track>> listTracks() {
    return _translate(() async {
      final rows = await _client
          .from(_tracksTable)
          .select('id, name, description, icon_name')
          .order('sort_order');

      return rows
          .map((row) {
            final id = RoadmapTrack.fromSlug(row['id'] as String?);
            if (id == null) return null;
            return Track(
              id: id,
              name: row['name'] as String? ?? '',
              description: row['description'] as String? ?? '',
              iconName: row['icon_name'] as String?,
            );
          })
          .whereType<Track>()
          .toList(growable: false);
    });
  }

  @override
  Future<List<TopicNode>> listTopics(RoadmapTrack track) {
    return _translate(() async {
      final rows = await _client
          .from(_topicsTable)
          .select(TopicModel.columns)
          .eq('track_id', track.slug)
          .order('sort_order');

      // Two queries and not a join: `user_progress` is protected by RLS to the
      // rows of the user, so fetching only the completed topics is a short
      // list and keeps the join from dragging in anyone else's progress.
      final completed = await _completedIds();

      return rows
          .map(
            (row) => TopicModel.fromJson(row).toEntity(
              isCompleted: completed.contains(row['id'] as String),
            ),
          )
          .whereType<TopicNode>()
          .toList(growable: false);
    });
  }

  Future<Set<String>> _completedIds() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return <String>{};

    final rows = await _client
        .from(_progressTable)
        .select('topic_id')
        .eq('user_id', id)
        .eq('status', 'completed');

    return rows.map((row) => row['topic_id'] as String).toSet();
  }

  /// Translates the backend errors into AuthFailure, just like the other
  /// repositories: presentation does not import supabase_flutter.
  Future<T> _translate<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      final text = e.toString().toLowerCase();
      final isNetwork = text.contains('socketexception') ||
          text.contains('clientexception') ||
          text.contains('failed host lookup') ||
          text.contains('connection') ||
          text.contains('timeout') ||
          text.contains('xmlhttprequest');

      throw AuthFailure(
        isNetwork ? AuthFailureKind.network : AuthFailureKind.unknown,
        technicalDetail: e.toString(),
      );
    }
  }
}
