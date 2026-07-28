import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/entities/lab_challenge.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/lab_repository.dart';

class LabRepositoryImpl implements LabRepository {
  const LabRepositoryImpl(this._client);

  final sb.SupabaseClient _client;
  static const String _table = 'lab_challenges';

  @override
  Future<List<LabChallenge>> getChallengesForTopic(String topicId) async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('topic_id', topicId)
          .order('sort_order');

      return rows.map((row) {
        final String type = row['challenge_type'] as String;
        final String id = row['id'] as String;
        final String tId = row['topic_id'] as String;
        final String question = row['question'] as String;
        final String? description = row['description'] as String?;
        final Map<String, dynamic> content = row['content'] as Map<String, dynamic>;

        switch (type) {
          case 'multiple_choice':
            return MultipleChoiceChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              options: Map<String, String>.from(content['options'] as Map),
              correctOptionId: content['correctOptionId'] as String,
            );
          case 'fill_blank':
            return FillBlankChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              codeSnippet: content['codeSnippet'] as String,
              correctAnswers: Map<String, String>.from(content['correctAnswers'] as Map),
              availableOptions: (content['availableOptions'] as List?)?.cast<String>(),
            );
          case 'order_logic':
            return OrderLogicChallenge(
              id: id,
              topicId: tId,
              question: question,
              description: description,
              blocks: Map<String, String>.from(content['blocks'] as Map),
              correctOrder: (content['correctOrder'] as List).cast<String>(),
            );
          default:
            throw Exception('Unknown challenge type: $type');
        }
      }).toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.message);
    } catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, technicalDetail: e.toString());
    }
  }
}
